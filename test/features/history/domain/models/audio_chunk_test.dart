import 'package:flutter_test/flutter_test.dart';
import 'package:echoscript/features/history/domain/models/audio_chunk.dart';

void main() {
  group('AudioChunk', () {
    test('transcriptionWords should split transcription correctly', () {
      final chunk = AudioChunk()
        ..transcription = 'Hello world this is a test';
      
      expect(chunk.transcriptionWords, ['Hello', 'world', 'this', 'is', 'a', 'test']);
    });

    test('transcriptionWords should return empty list if transcription is null', () {
      final chunk = AudioChunk()..transcription = null;
      
      expect(chunk.transcriptionWords, []);
    });

    test('transcriptionWords should handle multiple spaces', () {
      final chunk = AudioChunk()
        ..transcription = 'Hello   world  ';
      
      expect(chunk.transcriptionWords, ['Hello', 'world', '']);
    });
  });
}
