import 'package:flutter_test/flutter_test.dart';
import 'package:echoscript/features/history/domain/models/audio_chunk.dart';

void main() {
  group('AudioChunk Model Tests', () {
    test('AudioChunk holds properties correctly across status lifecycles', () {
      final now = DateTime.now();
      final chunk = AudioChunk()
        ..filePath = '/tmp/chunk_1.wav'
        ..status = 'PENDING'
        ..createdAt = now
        ..durationSeconds = 120
        ..wordCount = 0
        ..retryCount = 0;

      expect(chunk.filePath, equals('/tmp/chunk_1.wav'));
      expect(chunk.status, equals('PENDING'));
      expect(chunk.createdAt, equals(now));
      expect(chunk.durationSeconds, equals(120));
      expect(chunk.wordCount, equals(0));
      expect(chunk.retryCount, equals(0));
      expect(chunk.transcript, isNull);

      // Lifecycle update: Processing
      chunk.status = 'PROCESSING';
      expect(chunk.status, equals('PROCESSING'));

      // Lifecycle update: Done
      chunk.status = 'DONE';
      chunk.transcript = 'This is a test transcription result.';
      chunk.wordCount = chunk.transcript!.split(RegExp(r'\s+')).length;

      expect(chunk.status, equals('DONE'));
      expect(chunk.wordCount, equals(6));
      expect(chunk.transcript, equals('This is a test transcription result.'));
    });
  });
}
