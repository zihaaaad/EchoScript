import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WAV Header & File I/O Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('echoscript_wav_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Overwriting WAV header with FileMode.append preserves audio sample payload', () async {
      final testFile = File('${tempDir.path}/test_audio.wav');

      // 1. Allocate 44-byte header placeholder + 100 bytes of mock audio payload (144 bytes total)
      final initialData = Uint8List(144);
      for (int i = 44; i < 144; i++) {
        initialData[i] = (i % 256);
      }
      await testFile.writeAsBytes(initialData);

      expect(testFile.lengthSync(), equals(144));

      // 2. Build 44-byte WAV header
      final length = testFile.lengthSync();
      final dataSize = length - 44;
      final byteData = ByteData(44);

      byteData.setUint8(0, 0x52); // R
      byteData.setUint8(1, 0x49); // I
      byteData.setUint8(2, 0x46); // F
      byteData.setUint8(3, 0x46); // F
      byteData.setUint32(4, length - 8, Endian.little);
      byteData.setUint8(8, 0x57); // W
      byteData.setUint8(9, 0x41); // A
      byteData.setUint8(10, 0x56); // V
      byteData.setUint8(11, 0x45); // E
      byteData.setUint8(12, 0x66); // f
      byteData.setUint8(13, 0x6D); // m
      byteData.setUint8(14, 0x74); // t
      byteData.setUint8(15, 0x20); // space
      byteData.setUint32(16, 16, Endian.little); // Chunk size
      byteData.setUint16(20, 1, Endian.little); // Format: PCM
      byteData.setUint16(22, 1, Endian.little); // Channels: 1
      byteData.setUint32(24, 16000, Endian.little); // Sample rate
      byteData.setUint32(28, 32000, Endian.little); // Byte rate
      byteData.setUint16(32, 2, Endian.little); // Block align
      byteData.setUint16(34, 16, Endian.little); // Bits per sample
      byteData.setUint8(36, 0x64); // d
      byteData.setUint8(37, 0x61); // a
      byteData.setUint8(38, 0x74); // t
      byteData.setUint8(39, 0x61); // a
      byteData.setUint32(40, dataSize, Endian.little);

      // 3. Overwrite header using FileMode.append
      final raf = testFile.openSync(mode: FileMode.append);
      raf.setPositionSync(0);
      raf.writeFromSync(byteData.buffer.asUint8List());
      raf.closeSync();

      // 4. Verify total length is STILL 144 bytes (payload preserved, not truncated to 44)
      expect(testFile.lengthSync(), equals(144));

      // 5. Read back bytes and verify header magic and payload integrity
      final readBytes = await testFile.readAsBytes();
      expect(String.fromCharCodes(readBytes.sublist(0, 4)), equals('RIFF'));
      expect(String.fromCharCodes(readBytes.sublist(8, 12)), equals('WAVE'));
      expect(String.fromCharCodes(readBytes.sublist(12, 16)), equals('fmt '));
      expect(String.fromCharCodes(readBytes.sublist(36, 40)), equals('data'));

      // Verify payload at index 44..144 matches initial values
      for (int i = 44; i < 144; i++) {
        expect(readBytes[i], equals(i % 256));
      }
    });
  });
}
