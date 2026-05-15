import 'dart:async';
import 'package:isar/isar.dart';
import 'package:logger/logger.dart';
import '../datasources/recording_service.dart';
import '../datasources/transcription_service.dart';
import '../../../history/domain/models/audio_chunk.dart';

class RecordingManager {
  final Isar isar;
  final RecordingService _recordingService;
  final TranscriptionService _transcriptionService;
  final Logger _logger = Logger();
  
  StreamSubscription? _chunkWatcher;

  RecordingManager(this.isar, this._recordingService, this._transcriptionService);

  Future<void> startRecording() async {
    _logger.i("Manager: Starting Intelligence Unit...");
    
    // 1. Initialize hardware
    await _recordingService.init();
    
    // 2. Start gapless engine
    await _recordingService.start();
    
    // 3. Setup Event-Driven Transcription
    // Watch for any AudioChunk where status becomes 'pending'
    _chunkWatcher = isar.audioChunks
        .where()
        .filter()
        .statusEqualTo(ChunkStatus.pending)
        .watch(fireImmediately: true)
        .listen((chunks) {
      if (chunks.isNotEmpty) {
        _logger.i("Manager: Event detected - ${chunks.length} chunks pending. triggering pipeline.");
        _transcriptionService.processQueue();
      }
    });
  }

  Future<void> stopRecording() async {
    _logger.i("Manager: Stopping Intelligence Unit...");
    _chunkWatcher?.cancel();
    await _recordingService.stop();
    
    // Final processing pass to ensure no data is left behind
    await _transcriptionService.processQueue();
  }

  void dispose() {
    _chunkWatcher?.cancel();
    _recordingService.dispose();
  }
}
