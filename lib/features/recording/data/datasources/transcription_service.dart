import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:isar/isar.dart';
import '../../../history/domain/models/audio_chunk.dart';
import '../../../settings/domain/models/app_settings.dart';

class TranscriptionService {
  final Isar isar;
  bool _isProcessing = false;

  TranscriptionService(this.isar);

  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final settings = await isar.appSettings.get(0);
      if (settings == null || settings.geminiApiKey == null || settings.geminiApiKey!.isEmpty) {
        _isProcessing = false;
        return;
      }

      final pendingChunks = await isar.audioChunks
          .where()
          .filter()
          .statusEqualTo(ChunkStatus.pending)
          .findAll();

      for (final chunk in pendingChunks) {
        await _transcribeChunk(chunk, settings);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _transcribeChunk(AudioChunk chunk, AppSettings settings) async {
    try {
      chunk.status = ChunkStatus.transcribing;
      await isar.writeTxn(() => isar.audioChunks.put(chunk));

      final model = GenerativeModel(
        model: settings.geminiModel,
        apiKey: settings.geminiApiKey!,
      );

      final audioFile = File(chunk.filePath);
      if (!await audioFile.exists()) {
        chunk.status = ChunkStatus.failed;
        await isar.writeTxn(() => isar.audioChunks.put(chunk));
        return;
      }

      final bytes = await audioFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(settings.systemPrompt),
          DataPart('audio/aac', bytes),
        ])
      ];

      final response = await model.generateContent(content);
      
      chunk.transcription = response.text;
      chunk.status = ChunkStatus.completed;
      await isar.writeTxn(() => isar.audioChunks.put(chunk));

      // Auto-delete audio file after successful transcription to save space
      if (await audioFile.exists()) {
        await audioFile.delete();
      }
    } catch (e) {
      chunk.status = ChunkStatus.failed;
      await isar.writeTxn(() => isar.audioChunks.put(chunk));
    }
  }
}
