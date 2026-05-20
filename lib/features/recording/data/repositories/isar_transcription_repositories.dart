import 'package:isar/isar.dart';
import '../../../history/domain/models/audio_chunk.dart';
import '../../../settings/domain/models/app_settings.dart';
import '../../domain/repositories/transcription_repositories.dart';
import '../../../../core/constants/constants.dart';

class IsarTranscriptionRepository implements TranscriptionRepository {
  final Isar isar;

  IsarTranscriptionRepository(this.isar);

  @override
  Future<AppSettings> getSettings() async {
    final settings = await isar.appSettings.get(0);
    if (settings != null) return settings;

    // Return default settings if none exist
    final defaultSettings = AppSettings()
      ..id = 0
      ..gainMultiplier = 1.0
      ..chunkIntervalMinutes = AppConstants.defaultChunkIntervalMinutes
      ..systemPrompt = AppConstants.defaultSystemPrompt
      ..selectedModel = AppConstants.modelFlash
      ..isFirstLaunch = true;

    await saveSettings(defaultSettings);
    return defaultSettings;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await isar.writeTxn(() async {
      await isar.appSettings.put(settings);
    });
  }

  @override
  Future<void> insertChunk(AudioChunk chunk) async {
    await isar.writeTxn(() async {
      await isar.audioChunks.put(chunk);
    });
  }

  @override
  Future<void> updateChunk(AudioChunk chunk) async {
    await isar.writeTxn(() async {
      await isar.audioChunks.put(chunk);
    });
  }

  @override
  Future<AudioChunk?> getChunk(int id) async {
    return await isar.audioChunks.get(id);
  }

  @override
  Future<List<AudioChunk>> getAllChunks() async {
    return await isar.audioChunks.where().sortByCreatedAtDesc().findAll();
  }

  @override
  Stream<List<AudioChunk>> watchAllChunks() {
    return isar.audioChunks.where().sortByCreatedAtDesc().watch(fireImmediately: true);
  }

  @override
  Future<List<AudioChunk>> getPendingChunks() async {
    return await isar.audioChunks
        .filter()
        .statusEqualTo('PENDING')
        .or()
        .statusEqualTo('FAILED')
        .sortByCreatedAt()
        .findAll();
  }

  @override
  Future<void> deleteChunk(int id) async {
    await isar.writeTxn(() async {
      await isar.audioChunks.delete(id);
    });
  }

  @override
  Future<void> clearAllChunks() async {
    await isar.writeTxn(() async {
      await isar.audioChunks.clear();
    });
  }
}
