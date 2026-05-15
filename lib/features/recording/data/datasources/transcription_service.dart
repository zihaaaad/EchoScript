import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
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
  static const int maxConcurrency = 2; // SRE-compliant concurrency limit
  static const int maxRetries = 3;     // SRE-compliant retry limit

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

      final now = DateTime.now();

      // 1. Fetch eligible candidates (Pending OR Failed within retry limit)
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

      // 2. Filter by smart exponential backoff (2^retryCount minutes)
      final chunksToProcess = eligibleChunks.where((chunk) {
        if (chunk.status == ChunkStatus.pending) return true;
        if (chunk.lastAttemptTime == null) return true;
        
        final backoffDuration = Duration(minutes: 1 << chunk.retryCount);
        return now.isAfter(chunk.lastAttemptTime!.add(backoffDuration));
      }).toList();

      if (chunksToProcess.isEmpty) return;

      _logger.i("Transcription: Initiating dynamic pool for ${chunksToProcess.length} chunks");

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
          await _transcribeWithRetry(chunk, settings, apiKey);
        } catch (e) {
          _logger.e("Transcription: Worker error for ${chunk.id}", error: e);
        } finally {
          activeWorkers--;
          runNext();
        }
      }

      // Start initial batch of workers
      for (var i = 0; i < maxConcurrency && i < chunksToProcess.length; i++) {
        runNext();
      }

      await poolCompleter.future;
    } catch (e, stack) {
      _logger.e("Transcription: Pool critical failure", error: e, stackTrace: stack);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _transcribeWithRetry(AudioChunk chunk, AppSettings settings, String apiKey) async {
    try {
      final audioFile = File(chunk.filePath);
      if (!await audioFile.exists()) {
        await isar.writeTxn(() async {
          chunk.status = ChunkStatus.failed;
          chunk.errorMessage = "Source purged";
          chunk.lastAttemptTime = DateTime.now();
          await isar.audioChunks.put(chunk);
        });
        return;
      }

      await isar.writeTxn(() async {
        chunk.status = ChunkStatus.transcribing;
        chunk.lastAttemptTime = DateTime.now();
        await isar.audioChunks.put(chunk);
      });

      final model = GenerativeModel(
        model: settings.geminiModel,
        apiKey: apiKey,
        systemInstruction: Content.system(settings.systemPrompt),
      );

      // Memory-efficient handling: bytes read only during request scope
      var bytes = await audioFile.readAsBytes();
      final content = [
        Content.multi([
          DataPart('audio/wav', bytes),
        ])
      ];

      final response = await model.generateContent(content);
      
      // Explicitly clear byte reference for GC
      bytes = Uint8List(0);
      
      final text = response.text;

      if (text != null && text.isNotEmpty) {
        await isar.writeTxn(() async {
          chunk.transcription = text;
          chunk.status = ChunkStatus.completed;
          await isar.audioChunks.put(chunk);
        });
        
        _logger.i("Transcription: Archive successful for ${chunk.id}");

        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      } else {
        throw Exception("Incomplete AI response");
      }
    } catch (e) {
      _logger.w("Transcription: Chunk ${chunk.id} failure: $e");
      
      await isar.writeTxn(() async {
        chunk.status = ChunkStatus.failed;
        chunk.errorMessage = e.toString();
        chunk.retryCount++;
        chunk.lastAttemptTime = DateTime.now();
        await isar.audioChunks.put(chunk);
      });
    }
  }
}
