import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:echoscript/features/recording/data/datasources/transcription_service.dart';
import 'package:echoscript/features/recording/data/datasources/ai_engine.dart';
import 'package:echoscript/features/recording/domain/repositories/transcription_repositories.dart';
import 'package:echoscript/features/history/domain/models/audio_chunk.dart';
import 'package:echoscript/features/settings/domain/models/app_settings.dart';

class MockAudioChunkRepository extends Mock implements AudioChunkRepository {}
class MockAppSettingsRepository extends Mock implements AppSettingsRepository {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockAiEngine extends Mock implements AiEngine {}

void main() {
  late TranscriptionService transcriptionService;
  late MockAudioChunkRepository mockChunkRepo;
  late MockAppSettingsRepository mockSettingsRepo;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockAiEngine mockEngine;

  setUpAll(() {
    registerFallbackValue(AudioChunk());
    registerFallbackValue(AppSettings());
    registerFallbackValue(Content.text(''));
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockChunkRepo = MockAudioChunkRepository();
    mockSettingsRepo = MockAppSettingsRepository();
    mockSecureStorage = MockFlutterSecureStorage();
    mockEngine = MockAiEngine();
    
    transcriptionService = TranscriptionService(
      chunkRepo: mockChunkRepo,
      settingsRepo: mockSettingsRepo,
      secureStorage: mockSecureStorage,
    );
  });

  group('TranscriptionService AI Pipeline (Fully Mocked with Repositories)', () {
    test('testApiKey returns true on success', () async {
      when(() => mockEngine.generateContent(any())).thenAnswer((_) async => 'ok');

      final result = await transcriptionService.testApiKey('AIza_fake_key', 'fake_model', mockEngine: mockEngine);

      expect(result, isTrue);
    });

    test('processQueue completes transcription successfully', () async {
      // 1. Mock Settings
      final settings = AppSettings()
        ..geminiModel = 'gemini-pro'
        ..aiConcurrencyLimit = 1;
      when(() => mockSettingsRepo.getSettings()).thenAnswer((_) async => settings);

      // 2. Mock Secure Storage
      when(() => mockSecureStorage.read(key: 'gemini_api_key')).thenAnswer((_) async => 'AIza_fake_api_key');

      // 3. Mock Repositories
      final chunk = AudioChunk()
        ..id = 1
        ..filePath = 'test.wav'
        ..status = ChunkStatus.pending
        ..startTime = DateTime.now();
      
      when(() => mockChunkRepo.getPendingChunks(any())).thenAnswer((_) async => [chunk]);
      when(() => mockChunkRepo.updateChunk(any())).thenAnswer((_) async => {});

      // 4. Mock AI Response
      when(() => mockEngine.generateContent(any())).thenAnswer((_) async => 'Transcription result');

      // 5. Create a dummy file to satisfy File(chunk.filePath).exists()
      final dummyFile = File('test.wav');
      await dummyFile.writeAsBytes([0]);

      // 6. Execute
      await transcriptionService.processQueue(mockEngine: mockEngine);

      // 7. Verify
      verify(() => mockChunkRepo.updateChunk(any())).called(greaterThan(0));
      expect(chunk.status, ChunkStatus.completed);
      expect(chunk.transcription, 'Transcription result');

      // Cleanup
      if (await dummyFile.exists()) await dummyFile.delete();
    });

    test('processQueue handles AI failure with retry', () async {
      final settings = AppSettings()..aiConcurrencyLimit = 1;
      when(() => mockSettingsRepo.getSettings()).thenAnswer((_) async => settings);
      when(() => mockSecureStorage.read(key: 'gemini_api_key')).thenAnswer((_) async => 'AIza_fake_api_key');

      final chunk = AudioChunk()
        ..id = 2
        ..filePath = 'fail_test.wav'
        ..status = ChunkStatus.pending
        ..startTime = DateTime.now();
      
      when(() => mockChunkRepo.getPendingChunks(any())).thenAnswer((_) async => [chunk]);
      when(() => mockChunkRepo.updateChunk(any())).thenAnswer((_) async => {});

      when(() => mockEngine.generateContent(any())).thenThrow(Exception('AI ERROR'));

      final dummyFile = File('fail_test.wav');
      await dummyFile.writeAsBytes([0]);

      await transcriptionService.processQueue(mockEngine: mockEngine);

      expect(chunk.status, ChunkStatus.failed);
      expect(chunk.retryCount, 1);
      expect(chunk.errorMessage, contains('AI ERROR'));

      if (await dummyFile.exists()) await dummyFile.delete();
    });

    test('purgeOldData calls repository', () async {
      when(() => mockChunkRepo.getChunksOlderThan(any())).thenAnswer((_) async => []);

      await transcriptionService.purgeOldData();

      verify(() => mockChunkRepo.getChunksOlderThan(any())).called(1);
    });
  });
}
