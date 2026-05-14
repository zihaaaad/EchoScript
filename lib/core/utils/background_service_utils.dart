import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/history/domain/models/audio_chunk.dart';
import '../../features/settings/domain/models/app_settings.dart';
import '../../features/recording/data/repositories/recording_manager.dart';
import '../constants/constants.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      foregroundServiceNotificationId: 888,
      initialNotificationTitle: 'EchoScript Recording',
      initialNotificationContent: 'System Standby',
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

  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [AudioChunkSchema, AppSettingsSchema],
    directory: dir.path,
    name: AppConstants.dbName,
  );

  final recordingManager = RecordingManager(isar);

  service.on('startRecording').listen((event) {
    recordingManager.startRecording();
  });

  service.on('stopRecording').listen((event) {
    recordingManager.stopRecording();
  });

  // Keep service alive and sync status
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    final settings = await isar.appSettings.get(0);
    if (settings != null && service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "EchoScript Active",
        content: settings.isRecordingActive ? "Capture in progress..." : "System Standby",
      );
    }
  });
}
