import 'package:isar/isar.dart';
import '../../domain/repositories/transcription_repositories.dart';
import '../../../history/domain/models/audio_chunk.dart';
import '../../../settings/domain/models/app_settings.dart';

class IsarAudioChunkRepository implements AudioChunkRepository {
  final Isar isar;
  IsarAudioChunkRepository(this.isar);

  @override
  Future<List<AudioChunk>> getPendingChunks(int maxRetries) async =>
      isar.audioChunks
          .where()
          .filter()
          .group((q) => q
            .statusEqualTo(ChunkStatus.pending)
            .or()
            .group((inner) => inner
              .statusEqualTo(ChunkStatus.failed)
              .and()
              .retryCountLessThan(maxRetries)
            )
          )
          .findAll();

  @override
  Future<List<AudioChunk>> getChunksOlderThan(DateTime time) async =>
      isar.audioChunks.filter().startTimeLessThan(time).findAll();

  @override
  Future<void> updateChunk(AudioChunk chunk) async =>
      isar.writeTxn(() => isar.audioChunks.put(chunk));

  @override
  Future<void> deleteChunk(int id) async =>
      isar.writeTxn(() => isar.audioChunks.delete(id));

  @override
  Future<int> purgeCompletedBefore(DateTime time) async =>
      isar.writeTxn(() => isar.audioChunks
          .where()
          .filter()
          .statusEqualTo(ChunkStatus.completed)
          .startTimeLessThan(time)
          .deleteAll());
}

class IsarAppSettingsRepository implements AppSettingsRepository {
  final Isar isar;
  IsarAppSettingsRepository(this.isar);

  @override
  Future<AppSettings?> getSettings() async => isar.appSettings.get(0);
}
