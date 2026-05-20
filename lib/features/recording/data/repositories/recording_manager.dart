import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recording_manager.g.dart';

class RecordingStateModel {
  final bool isRecording;
  final int elapsedSeconds;
  final int queueCount;
  final String? activeFilePath;
  final String? diskSpaceWarning;

  RecordingStateModel({
    required this.isRecording,
    required this.elapsedSeconds,
    required this.queueCount,
    this.activeFilePath,
    this.diskSpaceWarning,
  });

  RecordingStateModel copyWith({
    bool? isRecording,
    int? elapsedSeconds,
    int? queueCount,
    String? activeFilePath,
    String? diskSpaceWarning,
  }) {
    return RecordingStateModel(
      isRecording: isRecording ?? this.isRecording,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      queueCount: queueCount ?? this.queueCount,
      activeFilePath: activeFilePath ?? this.activeFilePath,
      diskSpaceWarning: diskSpaceWarning ?? this.diskSpaceWarning,
    );
  }
}

@riverpod
class RecordingManager extends _$RecordingManager {
  StreamSubscription? _updateSubscription;
  StreamSubscription? _warningSubscription;
  Timer? _heartbeatTimer;

  @override
  RecordingStateModel build() {
    ref.onDispose(() {
      _updateSubscription?.cancel();
      _warningSubscription?.cancel();
      _heartbeatTimer?.cancel();
    });

    _listenToService();

    return RecordingStateModel(
      isRecording: false,
      elapsedSeconds: 0,
      queueCount: 0,
    );
  }

  void _listenToService() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();

    state = RecordingStateModel(
      isRecording: isRunning,
      elapsedSeconds: 0,
      queueCount: 0,
    );

    _updateSubscription = service.on('recordingUpdate').listen((event) {
      if (event != null) {
        state = state.copyWith(
          isRecording: true,
          elapsedSeconds: event['elapsedSeconds'] as int? ?? 0,
          activeFilePath: event['activeFilePath'] as String?,
          queueCount: event['queueCount'] as int? ?? 0,
        );
      }
    });

    _warningSubscription = service.on('diskSpaceWarning').listen((event) {
      if (event != null) {
        final free = event['freeSpace'] as double? ?? 0.0;
        state = state.copyWith(
          diskSpaceWarning: "Low space: ${free.toStringAsFixed(1)} MB remaining. Recording paused.",
        );
      }
    });

    // Check service state running heartbeat
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final running = await service.isRunning();
      if (running != state.isRecording) {
        state = state.copyWith(
          isRecording: running,
          elapsedSeconds: running ? state.elapsedSeconds : 0,
          activeFilePath: running ? state.activeFilePath : null,
          diskSpaceWarning: running ? state.diskSpaceWarning : null,
        );
      }
    });
  }

  Future<void> startRecording() async {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    if (!running) {
      await service.startService();
      state = state.copyWith(isRecording: true, elapsedSeconds: 0);
    }
  }

  Future<void> stopRecording() async {
    final service = FlutterBackgroundService();
    final running = await service.isRunning();
    if (running) {
      service.invoke('stopService');
      state = state.copyWith(isRecording: false, elapsedSeconds: 0);
    }
  }

  void triggerUpload() {
    FlutterBackgroundService().invoke('triggerUpload');
  }
}
