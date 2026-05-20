import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_session/audio_session.dart';

class RecordingService {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;

  IOSink? _activeSink;
  File? _activeFile;
  String? _activeFilePath;
  DateTime? _activeStartTime;

  double _gainMultiplier = 1.0;
  StreamSubscription? _recordingStreamSubscription;

  bool get isRecording => _isRecording;
  String? get activeFilePath => _activeFilePath;
  DateTime? get activeStartTime => _activeStartTime;

  void setGain(double gain) {
    _gainMultiplier = gain;
  }

  Future<void> init() async {
    _recorder = FlutterSoundRecorder();
    await _recorder!.openRecorder();

    // Setup audio session for background recording
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
          AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));
  }

  Future<void> start(double gain) async {
    if (_isRecording) return;
    _gainMultiplier = gain;

    // Create temp file for recording
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _activeFilePath = '${tempDir.path}/chunk_$timestamp.wav';
    _activeFile = File(_activeFilePath!);
    
    // Create the file and allocate 44 bytes of zeros for the WAV header
    await _activeFile!.writeAsBytes(Uint8List(44));
    _activeSink = _activeFile!.openWrite(mode: FileMode.append);
    _activeStartTime = DateTime.now();

    final recordingConsumer = StreamController<Uint8List>();
    _recordingStreamSubscription = recordingConsumer.stream.listen((rawData) {
      if (_activeSink != null) {
        final processedData = _applyGain(rawData, _gainMultiplier);
        _activeSink!.add(processedData);
      }
    });

    await _recorder!.startRecorder(
      toStream: recordingConsumer.sink,
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 16000,
    );

    _isRecording = true;
  }

  /// Seamlessly switches the output to a new file, returning the path to the completed file.
  Future<String?> rotate() async {
    if (!_isRecording || _activeFile == null || _activeSink == null) return null;

    final oldPath = _activeFilePath;
    final oldSink = _activeSink;
    final oldFile = _activeFile;

    // 1. Prepare the next file and sink
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newPath = '${tempDir.path}/chunk_$timestamp.wav';
    final newFile = File(newPath);
    await newFile.writeAsBytes(Uint8List(44));
    final newSink = newFile.openWrite(mode: FileMode.append);

    // 2. Perform the swap within <50ms window
    _activeFile = newFile;
    _activeFilePath = newPath;
    _activeSink = newSink;
    _activeStartTime = DateTime.now();

    // 3. Finalize the old file in the background
    if (oldSink != null && oldFile != null && oldPath != null) {
      await oldSink.flush();
      await oldSink.close();
      _writeWavHeader(oldFile, 16000, 1, 16);
    }

    return oldPath;
  }

  Future<String?> stop() async {
    if (!_isRecording) return null;

    await _recorder!.stopRecorder();
    if (_recordingStreamSubscription != null) {
      await _recordingStreamSubscription!.cancel();
      _recordingStreamSubscription = null;
    }

    final finishedPath = _activeFilePath;

    if (_activeSink != null && _activeFile != null) {
      await _activeSink!.flush();
      await _activeSink!.close();
      _activeSink = null;
      _writeWavHeader(_activeFile!, 16000, 1, 16);
      _activeFile = null;
    }

    _isRecording = false;
    _activeFilePath = null;
    _activeStartTime = null;

    return finishedPath;
  }

  Future<void> dispose() async {
    await stop();
    if (_recorder != null) {
      await _recorder!.closeRecorder();
      _recorder = null;
    }
  }

  Uint8List _applyGain(Uint8List rawBytes, double gain) {
    if (gain == 1.0) return rawBytes;

    final data = ByteData.sublistView(rawBytes);
    final length = rawBytes.length ~/ 2;
    final output = Uint8List(rawBytes.length);
    final outputData = ByteData.sublistView(output);

    for (int i = 0; i < length; i++) {
      final sample = data.getInt16(i * 2, Endian.little);
      double adjusted = sample * gain;

      if (adjusted > 32767) adjusted = 32767;
      if (adjusted < -32768) adjusted = -32768;

      outputData.setInt16(i * 2, adjusted.toInt(), Endian.little);
    }
    return output;
  }

  void _writeWavHeader(File file, int sampleRate, int numChannels, int bitsPerSample) {
    try {
      final length = file.lengthSync();
      final dataSize = length - 44;
      final byteData = ByteData(44);

      // RIFF header
      byteData.setUint8(0, 0x52); // R
      byteData.setUint8(1, 0x49); // I
      byteData.setUint8(2, 0x46); // F
      byteData.setUint8(3, 0x46); // F
      byteData.setUint32(4, length - 8, Endian.little);
      byteData.setUint8(8, 0x57); // W
      byteData.setUint8(9, 0x41); // A
      byteData.setUint8(10, 0x56); // V
      byteData.setUint8(11, 0x45); // E

      // fmt subchunk
      byteData.setUint8(12, 0x66); // f
      byteData.setUint8(13, 0x6D); // m
      byteData.setUint8(14, 0x74); // t
      byteData.setUint8(15, 0x20); // space
      byteData.setUint32(16, 16, Endian.little); // Chunk size
      byteData.setUint16(20, 1, Endian.little); // Format: PCM
      byteData.setUint16(22, numChannels, Endian.little);
      byteData.setUint32(24, sampleRate, Endian.little);
      final byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
      byteData.setUint32(28, byteRate, Endian.little);
      final blockAlign = numChannels * (bitsPerSample ~/ 8);
      byteData.setUint16(32, blockAlign, Endian.little);
      byteData.setUint16(34, bitsPerSample, Endian.little);

      // data subchunk
      byteData.setUint8(36, 0x64); // d
      byteData.setUint8(37, 0x61); // a
      byteData.setUint8(38, 0x74); // t
      byteData.setUint8(39, 0x61); // a
      byteData.setUint32(40, dataSize, Endian.little);

      // Overwrite the first 44 bytes with correct header
      final raf = file.openSync(mode: FileMode.write);
      raf.setPositionSync(0);
      raf.writeFromSync(byteData.buffer.asUint8List());
      raf.closeSync();
    } catch (e) {
      // Log or handle error writing header
    }
  }
}
