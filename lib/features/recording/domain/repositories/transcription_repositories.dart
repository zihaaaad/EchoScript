import '../../../history/domain/models/audio_chunk.dart';

abstract class AudioChunkRepository {
  Future<List<AudioChunk>> getPendingChunks(int maxRetries);
  Future<List<AudioChunk>> getChunksOlderThan(DateTime time);
  Future<List<AudioChunk>> getCompletedChunksToday();
  Future<void> updateChunk(AudioChunk chunk);
  Future<void> deleteChunk(int id);
  Future<int> purgeCompletedBefore(DateTime time);
}

abstract class AppSettingsRepository {
  Future<dynamic> getSettings(); // dynamic to avoid strong coupling for now
}
