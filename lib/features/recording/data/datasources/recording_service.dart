import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/constants.dart';
import '../../../history/domain/models/audio_chunk.dart';

class RecordingService {
  final Isar isar;
  FlutterSoundRecorder? _recorder;
  Timer? _rotationTimer;
  String? _currentPath;
  DateTime? _startTime;

  RecordingService(this.isar);

  Future<void> init() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  Future<void> start() async {
    if (await Permission.microphone.request().isGranted) {
      await _startNewChunk();
      _rotationTimer = Timer.periodic(
        Duration(seconds: AppConstants.chunkDurationSeconds),
        (_) => _rotateChunk(),
      );
    }
  }

  Future<void> stop() async {
    _rotationTimer?.cancel();
    await _stopCurrentChunk();
    await _recorder!.closeRecorder();
  }

  Future<void> _startNewChunk() async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.aac';
    _currentPath = '${dir.path}/$fileName';
    _startTime = DateTime.now();

    final chunk = AudioChunk()
      ..filePath = _currentPath!
      ..startTime = _startTime!
      ..status = ChunkStatus.recording;

    await isar.writeTxn(() => isar.audioChunks.put(chunk));
    await _recorder!.startRecorder(toFile: _currentPath);
  }

  Future<void> _stopCurrentChunk() async {
    if (_recorder!.isRecording) {
      await _recorder!.stopRecorder();
      final chunk = await isar.audioChunks
          .where()
          .filter()
          .filePathEqualTo(_currentPath!)
          .findFirst();

      if (chunk != null) {
        chunk.status = ChunkStatus.pending;
        chunk.endTime = DateTime.now();
        await isar.writeTxn(() => isar.audioChunks.put(chunk));
      }
    }
  }

  Future<void> _rotateChunk() async {
    await _stopCurrentChunk();
    await _startNewChunk();
  }

  void dispose() {
    _rotationTimer?.cancel();
    _recorder?.closeRecorder();
  }
}
