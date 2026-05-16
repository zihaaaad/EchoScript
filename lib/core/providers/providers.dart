import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/recording/data/datasources/transcription_service.dart';
import '../../features/recording/data/repositories/isar_transcription_repositories.dart';
import '../../features/recording/domain/repositories/transcription_repositories.dart';
import '../../main.dart';
import '../utils/diagnostic_service.dart';

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

final diagnosticServiceProvider = Provider<DiagnosticService>((ref) {
  final transcriptionService = ref.watch(transcriptionServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final isar = ref.watch(isarProvider);
  return DiagnosticService(
    transcriptionService: transcriptionService,
    secureStorage: secureStorage,
    isar: isar,
  );
});

final systemHealthProvider = StreamProvider<SystemHealth>((ref) async* {
  final diagnosticService = ref.watch(diagnosticServiceProvider);
  
  // Initial check
  yield await diagnosticService.runFullDiagnostics();
  
  // Periodic check every 5 minutes
  yield* Stream.periodic(const Duration(minutes: 5)).asyncMap((_) => 
    diagnosticService.runFullDiagnostics()
  );
});
