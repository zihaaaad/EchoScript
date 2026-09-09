import '../../../history/domain/models/audio_chunk.dart';
import '../../../settings/domain/models/app_settings.dart';

abstract class TranscriptionRepository {
  // Settings CRUD
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);

  // AudioChunk CRUD
  Future<void> insertChunk(AudioChunk chunk);
  Future<void> updateChunk(AudioChunk chunk);
  Future<AudioChunk?> getChunk(int id);
  Future<List<AudioChunk>> getAllChunks();
  Stream<List<AudioChunk>> watchAllChunks();
  Future<List<AudioChunk>> getPendingChunks();
  Future<void> recoverOrphanedProcessingChunks();
  Future<void> deleteChunk(int id);
  Future<void> clearAllChunks();
}

