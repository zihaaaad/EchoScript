import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:audio_session/audio_session.dart';
import '../../../../core/constants/constants.dart';
import '../../../history/domain/models/audio_chunk.dart';
import '../../../settings/domain/models/app_settings.dart';

class RecordingService {
  final Isar isar;
  final Logger _logger = Logger();
  
  FlutterSoundRecorder? _recorder;
  Timer? _rotationTimer;
  IOSink? _currentSink;
  String? _currentPath;
  int? _currentChunkId;
  int _currentByteCount = 0;
  bool _shouldBeRecording = false;
  StreamSubscription? _interruptionSubscription;
  final _dbController = StreamController<double>.broadcast();

  Stream<double> get onDbChanged => _dbController.stream;

  RecordingService(this.isar);

  Future<void> init() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();
    
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth | 
                                     AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    _interruptionSubscription = session.interruptionEventStream.listen((event) {
      if (event.begin) {
        _logger.w('Recording: Hardware hijacked (Interruption began)');
        _pauseInternal();
      } else {
        _logger.i('Recording: Hardware available (Interruption ended)');
        if (_shouldBeRecording) {
          _resumeInternal();
        }
      }
    });
  }

  Future<void> start() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        _shouldBeRecording = true;
        await _startGaplessRecording();
        
        final settings = await isar.appSettings.get(0);
        final durationSeconds = (settings?.chunkDurationMinutes ?? 30) * 60;

        _rotationTimer?.cancel();
        _rotationTimer = Timer.periodic(
          Duration(seconds: durationSeconds),
          (_) => _rotateChunk(),
        );
      } else {
        _logger.e('Recording: Microphone permission denied');
      }
    } catch (e, stack) {
      _logger.e('Recording: Failed to start', error: e, stackTrace: stack);
    }
  }

  Future<void> _startGaplessRecording() async {
    final streamController = StreamController<Uint8List>();
    
    await _openNewFileSink();

    final settings = await isar.appSettings.get(0);
    final gainDb = settings?.audioGainDb ?? 0.0;
    final multiplier = _getGainMultiplier(gainDb);

    await _recorder!.startRecorder(
      toStream: streamController.sink,
      codec: Codec.pcm16,
      sampleRate: AppConstants.sampleRate,
      numChannels: 1,
    );

    streamController.stream.listen((data) {
      try {
        var processedData = data;
        
        if (multiplier != 1.0) {
          processedData = _applyGain(data, multiplier);
        }
        
        _calculateAndEmitDb(processedData);
        
        _currentSink?.add(processedData);
        _currentByteCount += processedData.length;
      } catch (e, stack) {
        _logger.e('Recording: Error processing or writing audio chunk', error: e, stackTrace: stack);
      }
    });
  }

  void _calculateAndEmitDb(Uint8List data) {
    final samples = data.buffer.asInt16List();
    if (samples.isEmpty) return;

    double sumSquared = 0;
    for (var i = 0; i < samples.length; i++) {
      final sample = samples[i].toDouble();
      sumSquared += sample * sample;
    }
    
    final rms = math.sqrt(sumSquared / samples.length);
    // Reference for PCM 16-bit is 32768
    var db = rms > 0 ? 20 * math.log(rms / 32768.0) / math.ln10 : -60.0;
    
    // Normalize for UI (clamp between -60 and 0)
    if (db < -60) db = -60;
    if (db > 0) db = 0;
    
    _dbController.add(db);
  }

  double _getGainMultiplier(double db) {
    if (db == 0.0) return 1.0;
    return math.pow(10, db / 20).toDouble();
  }

  Uint8List _applyGain(Uint8List rawData, double multiplier) {
    final samples = rawData.buffer.asInt16List();
    final processedSamples = Int16List(samples.length);
    
    for (var i = 0; i < samples.length; i++) {
      var value = (samples[i] * multiplier).toInt();
      // Clip to Int16 range
      if (value > 32767) value = 32767;
      if (value < -32768) value = -32768;
      processedSamples[i] = value;
    }
    
    return processedSamples.buffer.asUint8List();
  }

  void _pauseInternal() async {
    if (_recorder?.isRecording ?? false) {
      await _recorder!.stopRecorder();
      _logger.i('Recording: Paused due to hijack');
    }
  }

  void _resumeInternal() async {
    if (_shouldBeRecording && !(_recorder?.isRecording ?? false)) {
      _logger.i('Recording: Resuming capture...');
      await _startGaplessRecording();
    }
  }

  Future<void> _openNewFileSink() async {
    try {
      final dir = await getTemporaryDirectory();
      
      // Proactive storage safety check
      // Try to create a tiny sentinel file to ensure we have write permissions and space
      final sentinel = File('${dir.path}/.storage_sentinel');
      try {
        await sentinel.writeAsString('OK');
      } catch (e) {
        if (e is OSError && e.errorCode == 28) {
          _logger.e('Recording: CRITICAL - Storage overflow detected (No space left on device)');
          await stop();
          return;
        }
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${dir.path}/chunk_$timestamp.wav'; 
      final startTime = DateTime.now();
      
      final chunk = AudioChunk()
        ..filePath = newPath
        ..startTime = startTime
        ..status = ChunkStatus.recording;

      await isar.writeTxn(() async {
        _currentChunkId = await isar.audioChunks.put(chunk);
      });

      final newFile = File(newPath);
      _currentSink = newFile.openWrite();
      _currentPath = newPath;
      _currentByteCount = 0;
      
      // Write placeholder for WAV header (44 bytes)
      _currentSink!.add(Uint8List(44)); 
      
      _logger.i('Recording: Opened new sink at $_currentPath');
    } catch (e, stack) {
      _logger.e('Recording: Critical failure opening new sink', error: e, stackTrace: stack);
      await stop(); // Shutdown to prevent data loss/null sink streaming
    }
  }

  Future<void> _rotateChunk() async {
    _logger.i('Recording: Rotating chunk gaplessly...');
    final oldSink = _currentSink;
    final oldPath = _currentPath;
    final oldChunkId = _currentChunkId;
    final oldByteCount = _currentByteCount;

    try {
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
    } catch (e) {
      _logger.e('Recording: Rotation failure', error: e);
      // Ensure old sink is closed if new one fails and we stop
      await oldSink?.close();
    }
  }

  Future<void> _finalizeWavHeader(String path, int byteCount) async {
    final raf = await File(path).open(mode: FileMode.append);
    await raf.setPosition(0);
    final header = _createWavHeader(byteCount);
    await raf.writeFrom(header);
    await raf.close();
    _logger.i('Recording: Finalized WAV header for $path ($byteCount bytes)');
  }

  Uint8List _createWavHeader(int pcmLength) {
    const sampleRate = AppConstants.sampleRate;
    const channels = 1;
    const byteRate = sampleRate * channels * 2;
    const blockAlign = channels * 2;
    
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
      _shouldBeRecording = false;
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
      _logger.e('Recording: Error during stop', error: e);
    }
  }

  void dispose() {
    _rotationTimer?.cancel();
    _interruptionSubscription?.cancel();
    _recorder?.closeRecorder();
  }
}
