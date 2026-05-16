import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'ai_engine.dart';
import '../../domain/repositories/transcription_repositories.dart';
import '../../../history/domain/models/audio_chunk.dart';
import '../../../settings/domain/models/app_settings.dart';

class TranscriptionService {
  final AudioChunkRepository chunkRepo;
  final AppSettingsRepository settingsRepo;
  final FlutterSecureStorage secureStorage;
  final Logger _logger = Logger();
  final Dio _dio = Dio();
  
  bool _isProcessing = false;
  static const int maxRetries = 3;

  TranscriptionService({
    required this.chunkRepo,
    required this.settingsRepo,
    required this.secureStorage,
  });

  Future<bool> testApiKey(String apiKey, String modelName, {AiEngine? mockEngine}) async {
    if (!apiKey.startsWith('AIza')) {
      _logger.w('Transcription: API Key test failed - Invalid format (must start with "AIza")');
      return false;
    }
    try {
      final engine = mockEngine ?? GeminiEngine(GenerativeModel(
        model: modelName,
        apiKey: apiKey,
      ));
      // Simple prompt to test connectivity
      final content = [Content.text('Say "ok"')];
      final text = await engine.generateContent(content);
      return text != null;
    } catch (e) {
      _logger.e('Transcription: API Key test failed', error: e);
      return false;
    }
  }

  Future<void> purgeOldData() async {
    try {
      final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));
      final oldChunks = await chunkRepo.getChunksOlderThan(twentyFourHoursAgo);
      
      var deletedFiles = 0;
      for (final chunk in oldChunks) {
        final file = File(chunk.filePath);
        if (await file.exists()) {
          await file.delete();
          deletedFiles++;
        }
        await chunkRepo.deleteChunk(chunk.id);
      }
      
      if (oldChunks.isNotEmpty) {
        _logger.i('Transcription: Purged ${oldChunks.length} legacy sessions ($deletedFiles files deleted)');
      }
    } catch (e) {
      _logger.e('Transcription: Purge protocol failure', error: e);
    }
  }

  Future<void> processQueue({AiEngine? mockEngine}) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final settings = await settingsRepo.getSettings() as AppSettings?;
      if (settings == null) return;

      final apiKey = await secureStorage.read(key: 'gemini_api_key');
      if (apiKey == null || apiKey.isEmpty || !apiKey.startsWith('AIza')) {
        _logger.w('Transcription: Invalid or missing API Key. Must start with "AIza".');
        return;
      }

      final now = DateTime.now();

      // 1. Fetch eligible candidates (Pending OR Failed within retry limit)
      final eligibleChunks = await chunkRepo.getPendingChunks(maxRetries);

      // 2. Filter by smart exponential backoff (2^retryCount minutes)
      final chunksToProcess = eligibleChunks.where((chunk) {
        if (chunk.status == ChunkStatus.pending) return true;
        if (chunk.lastAttemptTime == null) return true;
        
        final backoffDuration = Duration(minutes: 1 << chunk.retryCount);
        return now.isAfter(chunk.lastAttemptTime!.add(backoffDuration));
      }).toList();

      if (chunksToProcess.isEmpty) return;

      _logger.i('Transcription: Initiating dynamic pool for ${chunksToProcess.length} chunks (Limit: ${settings.aiConcurrencyLimit})');

      // 3. Dynamic Worker Pool Execution
      var activeWorkers = 0;
      var currentIndex = 0;
      final poolCompleter = Completer<void>();

      void runNext() async {
        if (currentIndex >= chunksToProcess.length) {
          if (activeWorkers == 0 && !poolCompleter.isCompleted) {
            poolCompleter.complete();
          }
          return;
        }

        final chunk = chunksToProcess[currentIndex++];
        activeWorkers++;

        try {
          await _transcribeWithRetry(chunk, settings, apiKey, mockEngine: mockEngine);
        } catch (e) {
          _logger.e('Transcription: Worker error for ${chunk.id}', error: e);
        } finally {
          activeWorkers--;
          runNext();
        }
      }

      // Start initial batch of workers based on user hardware preference
      for (var i = 0; i < settings.aiConcurrencyLimit && i < chunksToProcess.length; i++) {
        runNext();
      }

      await poolCompleter.future;
    } catch (e, stack) {
      _logger.e('Transcription: Pool critical failure', error: e, stackTrace: stack);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _transcribeWithRetry(AudioChunk chunk, AppSettings settings, String apiKey, {AiEngine? mockEngine}) async {
    try {
      final audioFile = File(chunk.filePath);
      if (!await audioFile.exists()) {
        chunk.status = ChunkStatus.failed;
        chunk.errorMessage = 'Source purged';
        chunk.lastAttemptTime = DateTime.now();
        await chunkRepo.updateChunk(chunk);
        return;
      }

      chunk.status = ChunkStatus.transcribing;
      chunk.lastAttemptTime = DateTime.now();
      await chunkRepo.updateChunk(chunk);

      // 1. Upload to Gemini Files API using Streaming Multipart
      final String fileUri;
      if (mockEngine != null) {
        fileUri = 'https://mock.gemini/file/123';
      } else {
        fileUri = await _uploadToFilesApi(audioFile, apiKey);
      }
      
      final engine = mockEngine ?? GeminiEngine(GenerativeModel(
        model: settings.geminiModel,
        apiKey: apiKey,
        systemInstruction: Content.system(settings.systemPrompt),
      ));

      // 2. Transcribe using the File Reference (Zero Heap Spike)
      final content = [
        Content.multi([
          FilePart(Uri.parse(fileUri)),
        ])
      ];

      final text = await engine.generateContent(content);

      if (text != null && text.isNotEmpty) {
        chunk.transcription = text;
        chunk.status = ChunkStatus.completed;
        await chunkRepo.updateChunk(chunk);
        
        _logger.i('Transcription: Archive successful for ${chunk.id}');

        if (mockEngine == null && await audioFile.exists()) {
          await audioFile.delete();
        }
      } else {
        throw Exception('Incomplete AI response');
      }
    } catch (e) {
      _logger.w('Transcription: Chunk ${chunk.id} failure: $e');
      
      chunk.status = ChunkStatus.failed;
      chunk.errorMessage = e.toString();
      chunk.retryCount++;
      chunk.lastAttemptTime = DateTime.now();
      await chunkRepo.updateChunk(chunk);
    }
  }

  Future<String> _uploadToFilesApi(File file, String apiKey) async {
    _logger.d('Files API: Initiating streaming upload for ${file.path}');
    
    final uploadUrl = 'https://generativelanguage.googleapis.com/upload/v1beta/files?key=$apiKey';
    
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: 'recording.wav',
        contentType: DioMediaType.parse('audio/wav'),
      ),
    });

    final response = await _dio.post(
      uploadUrl,
      data: formData,
      options: Options(
        headers: {
          'X-Goog-Upload-Protocol': 'multipart',
        },
      ),
    );

    final fileUri = response.data['file']['uri'] as String;
    _logger.d('Files API: Upload successful, URI: $fileUri');
    return fileUri;
  }
}
