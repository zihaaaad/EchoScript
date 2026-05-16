import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:echoscript/main.dart';
import 'package:echoscript/core/providers/providers.dart';
import 'package:echoscript/features/settings/domain/models/app_settings.dart';
import 'package:echoscript/features/history/domain/models/audio_chunk.dart';
import 'package:echoscript/features/recording/domain/repositories/transcription_repositories.dart';

class MockIsar extends Mock implements Isar {}
class MockAppSettingsCollection extends Mock implements IsarCollection<AppSettings> {}
class MockAudioChunkCollection extends Mock implements IsarCollection<AudioChunk> {}
class MockAudioChunkRepository extends Mock implements AudioChunkRepository {}

void main() {
  late MockIsar mockIsar;
  late MockAppSettingsCollection mockSettingsCollection;
  late MockAudioChunkCollection mockChunkCollection;
  late MockAudioChunkRepository mockRepo;

  setUp(() {
    mockIsar = MockIsar();
    mockSettingsCollection = MockAppSettingsCollection();
    mockChunkCollection = MockAudioChunkCollection();
    mockRepo = MockAudioChunkRepository();
    
    // Setup Isar mock
    when(() => mockIsar.appSettings).thenReturn(mockSettingsCollection);
    when(() => mockIsar.collection<AudioChunk>()).thenReturn(mockChunkCollection);
    
    // Setup collections
    when(() => mockSettingsCollection.watchObject(any(), fireImmediately: any(named: 'fireImmediately')))
        .thenAnswer((_) => Stream.value(AppSettings()..isRecordingActive = false));
    
    when(() => mockChunkCollection.watchLazy(fireImmediately: any(named: 'fireImmediately')))
        .thenAnswer((_) => Stream.value(null));

    // Setup Repository mock
    when(() => mockRepo.getCompletedChunksToday()).thenAnswer((_) async => []);
  });

  testWidgets('EchoScript Dashboard smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(mockIsar),
          audioChunkRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const EchoScriptApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('EchoScript'), findsWidgets);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
