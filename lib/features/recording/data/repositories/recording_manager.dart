import 'dart:async';
import 'package:isar/isar.dart';
import '../datasources/recording_service.dart';
import '../datasources/transcription_service.dart';

class RecordingManager {
  final Isar isar;
  late RecordingService _recordingService;
  late TranscriptionService _transcriptionService;
  Timer? _queueTimer;

  RecordingManager(this.isar) {
    _recordingService = RecordingService(isar);
    _transcriptionService = TranscriptionService(isar);
  }

  Future<void> startRecording() async {
    await _recordingService.init();
    await _recordingService.start();
    
    // Start transcription queue processor
    _queueTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _transcriptionService.processQueue();
    });
  }

  Future<void> stopRecording() async {
    await _recordingService.stop();
    _queueTimer?.cancel();
    
    // Final processing attempt
    await _transcriptionService.processQueue();
  }

  void dispose() {
    _recordingService.dispose();
    _queueTimer?.cancel();
  }
}
