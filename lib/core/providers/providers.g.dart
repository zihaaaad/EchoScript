// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$secureStorageHash() => r'3e5177aefc9c0d43d9cb4fdca3bdc2dfcb36f13e';

/// See also [secureStorage].
@ProviderFor(secureStorage)
final secureStorageProvider =
    AutoDisposeProvider<FlutterSecureStorage>.internal(
  secureStorage,
  name: r'secureStorageProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$secureStorageHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SecureStorageRef = AutoDisposeProviderRef<FlutterSecureStorage>;
String _$isarHash() => r'912004b8692624ddeffe232aabf9e41a309a03d3';

/// See also [isar].
@ProviderFor(isar)
final isarProvider = AutoDisposeProvider<Isar>.internal(
  isar,
  name: r'isarProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isarHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef IsarRef = AutoDisposeProviderRef<Isar>;
String _$transcriptionRepositoryHash() =>
    r'0b2c55176b64377058e45ae210a5173f0961b5a4';

/// See also [transcriptionRepository].
@ProviderFor(transcriptionRepository)
final transcriptionRepositoryProvider =
    AutoDisposeProvider<TranscriptionRepository>.internal(
  transcriptionRepository,
  name: r'transcriptionRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$transcriptionRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TranscriptionRepositoryRef
    = AutoDisposeProviderRef<TranscriptionRepository>;
String _$settingsStateHash() => r'22c150295d852676576fd07f2deec4f5421f5dcd';

/// See also [SettingsState].
@ProviderFor(SettingsState)
final settingsStateProvider =
    AutoDisposeAsyncNotifierProvider<SettingsState, AppSettings>.internal(
  SettingsState.new,
  name: r'settingsStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SettingsState = AutoDisposeAsyncNotifier<AppSettings>;
String _$apiKeyStateHash() => r'81a8479e96f72e73ff1268c18ac91c8e96500803';

/// See also [ApiKeyState].
@ProviderFor(ApiKeyState)
final apiKeyStateProvider =
    AutoDisposeAsyncNotifierProvider<ApiKeyState, String?>.internal(
  ApiKeyState.new,
  name: r'apiKeyStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$apiKeyStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ApiKeyState = AutoDisposeAsyncNotifier<String?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
