import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../features/history/domain/models/audio_chunk.dart';
import '../../features/settings/domain/models/app_settings.dart';
import '../../features/recording/data/repositories/recording_manager.dart';
import '../../features/recording/data/datasources/recording_service.dart';
import '../../features/recording/data/datasources/transcription_service.dart';
import '../constants/constants.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      foregroundServiceNotificationId: 888,
      initialNotificationTitle: 'EchoScript Intelligence',
      initialNotificationContent: 'Initializing Engine...',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // 1. Setup Persistence & Security
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [AudioChunkSchema, AppSettingsSchema],
    directory: dir.path,
    name: AppConstants.dbName,
  );
  
  const secureStorage = FlutterSecureStorage();

  // 2. Dependency Injection
  final recordingService = RecordingService(isar);
  final transcriptionService = TranscriptionService(
    isar: isar,
    secureStorage: secureStorage,
  );
  final manager = RecordingManager(isar, recordingService, transcriptionService);

  // 3. Command Listeners
  service.on('startRecording').listen((event) async {
    await WakelockPlus.enable();
    await manager.startRecording();
  });

  service.on('stopRecording').listen((event) async {
    await manager.stopRecording();
    await WakelockPlus.disable();
  });

  service.on('stopService').listen((event) async {
    await manager.stopRecording();
    await WakelockPlus.disable();
    service.stopSelf();
  });

  // 4. Single Source of Truth: Event-Driven UI Updates
  // Watch for settings/state changes and update notification IMMEDIATELY
  isar.appSettings.watchObject(0, fireImmediately: true).listen((settings) {
    if (settings == null) return;
    
    final isActive = settings.isRecordingActive;
    
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: isActive ? "EchoScript: Active" : "EchoScript: Standby",
        content: isActive ? "Capturing professional intelligence..." : "System ready for capture",
      );
    }
    
    // Push real-time status back to UI Isolate
    service.invoke('statusUpdate', {
      'isActive': isActive,
      'timestamp': DateTime.now().toIso8601String(),
    });
  });

  // 5. Watch for Transcription Progress to update UI
  isar.audioChunks.filter().statusEqualTo(ChunkStatus.transcribing).watch().listen((chunks) {
    if (chunks.isNotEmpty) {
      service.invoke('statusUpdate', {
        'isTranscribing': true,
        'count': chunks.length,
      });
    } else {
      service.invoke('statusUpdate', {
        'isTranscribing': false,
      });
    }
  });
}
