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

  TranscriptionService({
    required this.isar,
    required this.secureStorage,
  });

  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final settings = await isar.appSettings.get(0);
      if (settings == null) {
        _logger.w("Transcription: App settings not found.");
        return;
      }

      final apiKey = await secureStorage.read(key: 'gemini_api_key');
      if (apiKey == null || apiKey.isEmpty) {
        _logger.w("Transcription: Gemini API Key not found in secure storage.");
        return;
      }

      final pendingChunks = await isar.audioChunks
          .where()
          .filter()
          .statusEqualTo(ChunkStatus.pending)
          .findAll();

      if (pendingChunks.isEmpty) return;

      _logger.i("Transcription: Processing ${pendingChunks.length} pending chunks.");

      for (final chunk in pendingChunks) {
        await _transcribeWithRetry(chunk, settings, apiKey);
      }
    } catch (e, stack) {
      _logger.e("Transcription: Queue processing error", error: e, stackTrace: stack);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _transcribeWithRetry(AudioChunk chunk, AppSettings settings, String apiKey) async {
    try {
      await isar.writeTxn(() async {
        chunk.status = ChunkStatus.transcribing;
        await isar.audioChunks.put(chunk);
      });

      final model = GenerativeModel(
        model: settings.geminiModel,
        apiKey: apiKey,
        systemInstruction: Content.system(settings.systemPrompt),
      );

      final audioFile = File(chunk.filePath);
      if (!await audioFile.exists()) {
        _logger.e("Transcription: Audio file missing at ${chunk.filePath}");
        await isar.writeTxn(() async {
          chunk.status = ChunkStatus.failed;
          chunk.errorMessage = "File missing";
          await isar.audioChunks.put(chunk);
        });
        return;
      }

      final bytes = await audioFile.readAsBytes();
      final content = [
        Content.multi([
          DataPart('audio/wav', bytes),
        ])
      ];

      final response = await model.generateContent(content);
      final text = response.text;

      if (text != null && text.isNotEmpty) {
        await isar.writeTxn(() async {
          chunk.transcription = text;
          chunk.status = ChunkStatus.completed;
          await isar.audioChunks.put(chunk);
        });
        
        _logger.i("Transcription: Completed for ${chunk.filePath}");

        // Atomic cleanup: only delete if transcription is safely in Isar
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      } else {
        throw Exception("Empty response from AI");
      }
    } catch (e, stack) {
      _logger.e("Transcription: Error for ${chunk.filePath}", error: e, stackTrace: stack);
      await isar.writeTxn(() async {
        chunk.status = ChunkStatus.failed;
        chunk.errorMessage = e.toString();
        chunk.retryCount++;
        await isar.audioChunks.put(chunk);
      });
    }
  }
}
