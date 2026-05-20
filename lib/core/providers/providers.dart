import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/recording/data/repositories/isar_transcription_repositories.dart';
import '../../features/recording/domain/repositories/transcription_repositories.dart';
import '../../features/settings/domain/models/app_settings.dart';
import '../constants/constants.dart';

part 'providers.g.dart';

@riverpod
FlutterSecureStorage secureStorage(SecureStorageRef ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
}

@riverpod
Isar isar(IsarRef ref) {
  throw UnimplementedError('Isar must be overridden in ProviderScope');
}

@riverpod
TranscriptionRepository transcriptionRepository(TranscriptionRepositoryRef ref) {
  final isarInstance = ref.watch(isarProvider);
  return IsarTranscriptionRepository(isarInstance);
}

@riverpod
class SettingsState extends _$SettingsState {
  @override
  FutureOr<AppSettings> build() async {
    final repo = ref.watch(transcriptionRepositoryProvider);
    return await repo.getSettings();
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.watch(transcriptionRepositoryProvider);
      await repo.saveSettings(settings);
      return settings;
    });
  }
}

@riverpod
class ApiKeyState extends _$ApiKeyState {
  @override
  FutureOr<String?> build() async {
    final secureStorage = ref.watch(secureStorageProvider);
    return await secureStorage.read(key: AppConstants.secureApiKeyName);
  }

  Future<void> setApiKey(String key) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final secureStorage = ref.watch(secureStorageProvider);
      if (key.trim().isEmpty) {
        await secureStorage.delete(key: AppConstants.secureApiKeyName);
        return null;
      } else {
        await secureStorage.write(key: AppConstants.secureApiKeyName, value: key.trim());
        return key.trim();
      }
    });
  }
}
