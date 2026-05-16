import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/recording/data/datasources/transcription_service.dart';
import '../../features/recording/data/repositories/isar_transcription_repositories.dart';
import '../../features/recording/domain/repositories/transcription_repositories.dart';
import '../../main.dart';

final audioChunkRepositoryProvider = Provider<AudioChunkRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return IsarAudioChunkRepository(isar);
});

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return IsarAppSettingsRepository(isar);
});

final transcriptionServiceProvider = Provider<TranscriptionService>((ref) {
  final chunkRepo = ref.watch(audioChunkRepositoryProvider);
  final settingsRepo = ref.watch(appSettingsRepositoryProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return TranscriptionService(
    chunkRepo: chunkRepo,
    settingsRepo: settingsRepo,
    secureStorage: secureStorage,
  );
});
