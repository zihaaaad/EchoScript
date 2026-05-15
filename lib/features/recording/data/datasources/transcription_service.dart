import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:isar/isar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../../history/domain/models/audio_chunk.dart';
import '../../../settings/domain/models/app_settings.dart';

class TranscriptionService {
  final Isar isar;
  final FlutterSecureStorage secureStorage;
  final Logger _logger = Logger();
  
  bool _isProcessing = false;
  static const int maxConcurrency = 2; // Big Tech Solution: Managed Concurrency
  static const int maxRetries = 3;     // Robust Retry Policy

  TranscriptionService({
    required this.isar,
    required this.secureStorage,
  });

  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final settings = await isar.appSettings.get(0);
      if (settings == null) return;

      final apiKey = await secureStorage.read(key: 'gemini_api_key');
      if (apiKey == null || apiKey.isEmpty) return;

      // Select chunks that are pending OR failed but eligible for retry
      final eligibleChunks = await isar.audioChunks
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

      if (eligibleChunks.isEmpty) return;

      _logger.i("Transcription: Processing ${eligibleChunks.length} chunks (Concurrent)");

      // Process in batches to avoid rate limits and OOM
      for (var i = 0; i < eligibleChunks.length; i += maxConcurrency) {
        final end = (i + maxConcurrency < eligibleChunks.length) 
            ? i + maxConcurrency 
            : eligibleChunks.length;
        
        final batch = eligibleChunks.sublist(i, end);
        await Future.wait(batch.map((chunk) => _transcribeWithRetry(chunk, settings, apiKey)));
      }
    } catch (e, stack) {
      _logger.e("Transcription: Queue critical failure", error: e, stackTrace: stack);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _transcribeWithRetry(AudioChunk chunk, AppSettings settings, String apiKey) async {
    try {
      // 1. Pre-flight checks
      final audioFile = File(chunk.filePath);
      if (!await audioFile.exists()) {
        await isar.writeTxn(() async {
          chunk.status = ChunkStatus.failed;
          chunk.errorMessage = "Source file purged or missing";
          await isar.audioChunks.put(chunk);
        });
        return;
      }

      // 2. State transition
      await isar.writeTxn(() async {
        chunk.status = ChunkStatus.transcribing;
        await isar.audioChunks.put(chunk);
      });

      // 3. AI Execution
      final model = GenerativeModel(
        model: settings.geminiModel,
        apiKey: apiKey,
        systemInstruction: Content.system(settings.systemPrompt),
      );

      // Warning: readAsBytes can OOM on very large files (e.g. >200MB)
      // For 30min WAV @ 16kHz Mono, it's ~57MB. Safe for most enterprise devices.
      final bytes = await audioFile.readAsBytes();
      final content = [
        Content.multi([
          DataPart('audio/wav', bytes),
        ])
      ];

      final response = await model.generateContent(content);
      final text = response.text;

      if (text != null && text.isNotEmpty) {
        // 4. Persistence
        await isar.writeTxn(() async {
          chunk.transcription = text;
          chunk.status = ChunkStatus.completed;
          await isar.audioChunks.put(chunk);
        });
        
        // 5. Cleanup
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      } else {
        throw Exception("AI returned empty transcription result.");
      }
    } catch (e) {
      _logger.w("Transcription: Chunk failed (${chunk.filePath}): $e");
      
      await isar.writeTxn(() async {
        chunk.status = ChunkStatus.failed;
        chunk.errorMessage = e.toString();
        chunk.retryCount++;
        await isar.audioChunks.put(chunk);
      });
    }
  }
}
