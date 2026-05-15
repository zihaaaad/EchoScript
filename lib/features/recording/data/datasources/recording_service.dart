import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import '../../../../core/constants/constants.dart';
import '../../../history/domain/models/audio_chunk.dart';

class RecordingService {
  final Isar isar;
  final Logger _logger = Logger();
  
  FlutterSoundRecorder? _recorder;
  Timer? _rotationTimer;
  IOSink? _currentSink;
  String? _currentPath;
  DateTime? _startTime;
  int? _currentChunkId;
  int _currentByteCount = 0;

  RecordingService(this.isar);

  Future<void> init() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
  }

  Future<void> start() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        await _startGaplessRecording();
        
        _rotationTimer = Timer.periodic(
          Duration(seconds: AppConstants.chunkDurationSeconds),
          (_) => _rotateChunk(),
        );
      } else {
        _logger.e("Recording: Microphone permission denied");
      }
    } catch (e, stack) {
      _logger.e("Recording: Failed to start", error: e, stackTrace: stack);
    }
  }

  Future<void> _startGaplessRecording() async {
    final streamController = StreamController<Uint8List>();
    
    await _openNewFileSink();

    await _recorder!.startRecorder(
      toStream: streamController.sink,
      codec: Codec.pcm16,
      sampleRate: AppConstants.sampleRate,
      numChannels: 1,
    );

    streamController.stream.listen((data) {
      _currentSink?.add(data);
      _currentByteCount += data.length;
    });
  }

  Future<void> _openNewFileSink() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentPath = '${dir.path}/chunk_$timestamp.wav'; 
    _startTime = DateTime.now();
    _currentByteCount = 0;
    
    final chunk = AudioChunk()
      ..filePath = _currentPath!
      ..startTime = _startTime!
      ..status = ChunkStatus.recording;

    await isar.writeTxn(() async {
      _currentChunkId = await isar.audioChunks.put(chunk);
    });

    _currentSink = File(_currentPath!).openWrite();
    
    // Write placeholder for WAV header (44 bytes)
    _currentSink!.add(Uint8List(44)); 
    
    _logger.i("Recording: Opened new sink at $_currentPath");
  }

  Future<void> _rotateChunk() async {
    _logger.i("Recording: Rotating chunk gaplessly...");
    final oldSink = _currentSink;
    final oldPath = _currentPath;
    final oldChunkId = _currentChunkId;
    final oldByteCount = _currentByteCount;

    await _openNewFileSink();

    if (oldSink != null && oldPath != null) {
      await oldSink.flush();
      await oldSink.close();
      await _finalizeWavHeader(oldPath, oldByteCount);
    }

    if (oldChunkId != null) {
      final chunk = await isar.audioChunks.get(oldChunkId);
      if (chunk != null) {
        chunk.status = ChunkStatus.pending;
        chunk.endTime = DateTime.now();
        await isar.writeTxn(() => isar.audioChunks.put(chunk));
      }
    }
  }

  Future<void> _finalizeWavHeader(String path, int byteCount) async {
    final raf = await File(path).open(mode: FileMode.write);
    final header = _createWavHeader(byteCount);
    await raf.writeFrom(header);
    await raf.close();
    _logger.i("Recording: Finalized WAV header for $path ($byteCount bytes)");
  }

  Uint8List _createWavHeader(int pcmLength) {
    final int sampleRate = AppConstants.sampleRate;
    final int channels = 1;
    final int byteRate = sampleRate * channels * 2;
    final int blockAlign = channels * 2;
    
    final header = ByteData(44);
    
    // "RIFF"
    header.setUint8(0, 0x52); header.setUint8(1, 0x49); header.setUint8(2, 0x46); header.setUint8(3, 0x46);
    // File size - 8
    header.setUint32(4, 36 + pcmLength, Endian.little);
    // "WAVE"
    header.setUint8(8, 0x57); header.setUint8(9, 0x41); header.setUint8(10, 0x56); header.setUint8(11, 0x45);
    // "fmt "
    header.setUint8(12, 0x66); header.setUint8(13, 0x6D); header.setUint8(14, 0x74); header.setUint8(15, 0x20);
    // Subchunk1Size (16 for PCM)
    header.setUint32(16, 16, Endian.little);
    // AudioFormat (1 for PCM)
    header.setUint16(20, 1, Endian.little);
    // NumChannels
    header.setUint16(22, channels, Endian.little);
    // SampleRate
    header.setUint32(24, sampleRate, Endian.little);
    // ByteRate
    header.setUint32(28, byteRate, Endian.little);
    // BlockAlign
    header.setUint16(32, blockAlign, Endian.little);
    // BitsPerSample
    header.setUint16(34, 16, Endian.little);
    // "data"
    header.setUint8(36, 0x64); header.setUint8(37, 0x61); header.setUint8(38, 0x74); header.setUint8(39, 0x61);
    // Subchunk2Size
    header.setUint32(40, pcmLength, Endian.little);
    
    return header.buffer.asUint8List();
  }

  Future<void> stop() async {
    try {
      _rotationTimer?.cancel();
      if (_recorder!.isRecording) {
        await _recorder!.stopRecorder();
      }
      
      if (_currentSink != null) {
        await _currentSink!.flush();
        await _currentSink!.close();
        
        if (_currentPath != null) {
          await _finalizeWavHeader(_currentPath!, _currentByteCount);
        }
        _currentSink = null;
      }

      if (_currentChunkId != null) {
        final chunk = await isar.audioChunks.get(_currentChunkId!);
        if (chunk != null) {
          chunk.status = ChunkStatus.pending;
          chunk.endTime = DateTime.now();
          await isar.writeTxn(() => isar.audioChunks.put(chunk));
        }
      }
    } catch (e) {
      _logger.e("Recording: Error during stop", error: e);
    }
  }

  void dispose() {
    _rotationTimer?.cancel();
    _recorder?.closeRecorder();
  }
}
