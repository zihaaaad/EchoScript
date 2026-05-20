import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:disk_space_2/disk_space_2.dart';

import '../constants/constants.dart';
import '../../features/history/domain/models/audio_chunk.dart';
import '../../features/settings/domain/models/app_settings.dart';
import '../../features/recording/data/repositories/isar_transcription_repositories.dart';
import '../../features/recording/data/datasources/recording_service.dart';
import '../../features/recording/data/datasources/ai_engine.dart';
import '../../features/recording/data/datasources/transcription_service.dart';

class BackgroundServiceUtils {
  BackgroundServiceUtils._();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Setup Local Notifications for Foreground Service on Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: 'Persistent notification for EchoScript recording.',
      importance: Importance.low,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: AppConstants.notificationChannelId,
        initialNotificationTitle: 'EchoScript Service',
        initialNotificationContent: 'Initializing background recorder...',
        foregroundServiceNotificationId: AppConstants.notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: (ServiceInstance service) => false,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Open Isar in background isolate
    final docDir = await getApplicationDocumentsDirectory();
    final isar = Isar.getInstance() ??
        await Isar.open(
          [AudioChunkSchema, AppSettingsSchema],
          directory: docDir.path,
        );

    final repo = IsarTranscriptionRepository(isar);
    final secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final aiEngine = AiEngine(secureStorage);
    final transcriptionService = TranscriptionService(repo, aiEngine);
    final recordingService = RecordingService();

    // 2. State & config cache
    final settings = await repo.getSettings();
    await recordingService.init();

    Timer? rotationTimer;
    Timer? uiUpdateTimer;
    Timer? diskCheckTimer;
    bool diskGuardActive = false;

    // Helper: start recording & loops
    Future<void> startRecordingFlow() async {
      if (recordingService.isRecording) return;

      // Acquire CPU Wakelock
      try {
        await WakelockPlus.enable();
      } catch (e) {
        print('Wakelock failed to acquire: $e');
      }

      await recordingService.start(settings.gainMultiplier);

      // Rotation timer
      final interval = Duration(minutes: settings.chunkIntervalMinutes);
      rotationTimer = Timer.periodic(interval, (timer) async {
        if (!recordingService.isRecording || diskGuardActive) return;

        final chunkStartTime = recordingService.activeStartTime ?? DateTime.now();
        final path = await recordingService.rotate();
        
        if (path != null) {
          final duration = DateTime.now().difference(chunkStartTime).inSeconds;
          final chunk = AudioChunk()
            ..filePath = path
            ..status = 'PENDING'
            ..createdAt = chunkStartTime
            ..durationSeconds = duration
            ..wordCount = 0
            ..retryCount = 0;

          await repo.insertChunk(chunk);
          
          // Trigger queue processing
          _runQueueSafely(isar, secureStorage, transcriptionService);
        }
      });

      // Disk Guard check loop (every 10 seconds)
      diskCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        try {
          final freeDiskMb = await DiskSpace.getFreeDiskSpace;
          if (freeDiskMb != null && freeDiskMb < 500) {
            // LOW STORAGE SPACE GUARD: Pause recording loop
            diskGuardActive = true;
            await recordingService.stop();
            
            // Notify UI and update notification
            if (service is AndroidServiceInstance) {
              service.setForegroundNotificationInfo(
                title: "EchoScript Paused — Low Space",
                content: "Free disk space is below 500MB. Recording paused.",
              );
            }
            service.invoke('diskSpaceWarning', {'freeSpace': freeDiskMb});
          } else if (diskGuardActive && freeDiskMb != null && freeDiskMb >= 500) {
            // Space cleared - resume
            diskGuardActive = false;
            await recordingService.start(settings.gainMultiplier);
          }
        } catch (_) {}
      });

      // Periodic Notification and UI updates (every second)
      if (service is AndroidServiceInstance) {
        service.setAsForegroundService();
        uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (!recordingService.isRecording) return;

          final elapsed = DateTime.now().difference(recordingService.activeStartTime ?? DateTime.now());
          final hours = elapsed.inHours.toString().padLeft(2, '0');
          final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
          final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
          final durationStr = "$hours:$minutes:$seconds";

          final pendingChunks = await repo.getPendingChunks();
          final queueCount = pendingChunks.length;

          service.setForegroundNotificationInfo(
            title: "Recording — $durationStr",
            content: queueCount > 0
                ? "Recording Active • $queueCount chunk(s) uploading"
                : "Recording Active • Audio synced",
          );

          // Broadcast stats to UI
          service.invoke('recordingUpdate', {
            'elapsedSeconds': elapsed.inSeconds,
            'activeFilePath': recordingService.activeFilePath,
            'queueCount': queueCount,
          });
        });
      }

      // Run transcription queue for any prior pending chunks
      _runQueueSafely(isar, secureStorage, transcriptionService);
    }

    // Helper: stop recording and cleanup
    Future<void> stopRecordingFlow() async {
      rotationTimer?.cancel();
      uiUpdateTimer?.cancel();
      diskCheckTimer?.cancel();

      try {
        await WakelockPlus.disable();
      } catch (_) {}

      final lastPath = await recordingService.stop();
      if (lastPath != null) {
        final chunkStartTime = recordingService.activeStartTime ?? DateTime.now();
        final duration = DateTime.now().difference(chunkStartTime).inSeconds;

        final chunk = AudioChunk()
          ..filePath = lastPath
          ..status = 'PENDING'
          ..createdAt = chunkStartTime
          ..durationSeconds = duration
          ..wordCount = 0
          ..retryCount = 0;

        await repo.insertChunk(chunk);
      }

      // Run final transcription queue
      await _runQueueSafely(isar, secureStorage, transcriptionService);

      // Run 24-Hour Privacy Purge
      await transcriptionService.run24HourAutoPurge();
    }

    // Start immediately on service start
    await startRecordingFlow();

    // Service message listeners
    service.on('stopService').listen((event) async {
      await stopRecordingFlow();
      await service.stopSelf();
    });

    service.on('triggerUpload').listen((event) {
      _runQueueSafely(isar, secureStorage, transcriptionService);
    });
  }

  static bool _queueIsRunning = false;

  static Future<void> _runQueueSafely(
      Isar isar,
      FlutterSecureStorage secureStorage,
      TranscriptionService service) async {
    if (_queueIsRunning) return;
    _queueIsRunning = true;

    try {
      final repo = IsarTranscriptionRepository(isar);
      while (true) {
        final pending = await repo.getPendingChunks();
        if (pending.isEmpty) break;

        final chunk = pending.first;
        final success = await service.transcribeChunk(chunk);
        if (!success) {
          // If transcription fails, the queue worker breaks to avoid infinite loops,
          // allowing next rotate/interval event or user trigger to wake it up.
          break;
        }
      }
    } catch (e) {
      print('Background queue runner encountered error: $e');
    } finally {
      _queueIsRunning = false;
    }
  }
}
