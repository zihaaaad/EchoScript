import 'dart:io';
import '../../domain/repositories/transcription_repositories.dart';
import '../../../history/domain/models/audio_chunk.dart';
import 'ai_engine.dart';
import '../../../../core/constants/constants.dart';

class TranscriptionService {
  final TranscriptionRepository _repository;
  final AiEngine _aiEngine;

  TranscriptionService(this._repository, this._aiEngine);

  /// Transcribes a single pending/failed chunk, handling uploads, API calls,
  /// database updates, error retries, and atomic file cleanup.
  /// Returns `true` if successful, `false` otherwise.
  Future<bool> transcribeChunk(AudioChunk chunk) async {
    final file = File(chunk.filePath);
    if (!await file.exists()) {
      // Audio file missing - mark as FAILED and don't retry
      chunk.status = 'FAILED';
      chunk.transcript = '[Error: Audio file not found on device]';
      await _repository.updateChunk(chunk);
      return false;
    }

    if (await file.length() <= 44) {
      // Audio file contains no PCM payload (empty recording)
      chunk.status = 'FAILED';
      chunk.transcript = '[Error: Audio recording is empty]';
      await _repository.updateChunk(chunk);
      return false;
    }

    final settings = await _repository.getSettings();
    int backoffSeconds = 5; // Adaptive initial backoff for transient issues

    for (int attempt = 1; attempt <= AppConstants.maxRetryCount; attempt++) {
      try {
        chunk.status = 'PROCESSING';
        await _repository.updateChunk(chunk);

        // 1. Upload audio to Gemini Files API
        final uploadResult = await _aiEngine.uploadAudioFile(file);
        final fileUri = uploadResult['uri']!;
        final fileRemoteName = uploadResult['name']!;

        String? transcriptText;
        try {
          // 2. Perform transcription
          transcriptText = await _aiEngine.transcribe(
            fileUri,
            settings.selectedModel,
            settings.systemPrompt,
          );
        } finally {
          // 3. Always clean up remote Gemini file immediately after transcription attempt
          await _aiEngine.deleteRemoteFile(fileRemoteName);
        }

        // 4. Update chunk status and write transcript to database
        chunk.transcript = transcriptText;
        chunk.status = 'DONE';
        chunk.wordCount = transcriptText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        await _repository.updateChunk(chunk);

        // 5. ATOMIC CLEANUP: Only delete local audio file AFTER Isar write is verified
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Log local file delete failure, but don't fail the operation
          print('Warning: Failed to delete local audio file: $e');
        }

        return true;
      } catch (e) {
        final errorStr = e.toString();
        print('Error during transcription attempt $attempt: $errorStr');

        // Fatal non-retryable errors (authentication, permission, or bad request)
        final isAuthOrFatalError = errorStr.contains('API Key is not configured') ||
            errorStr.contains('API_KEY_INVALID') ||
            errorStr.contains('401') ||
            errorStr.contains('403') ||
            errorStr.contains('400');

        final isLastAttempt = attempt == AppConstants.maxRetryCount || isAuthOrFatalError;

        if (isLastAttempt) {
          chunk.status = 'FAILED';
          chunk.retryCount = attempt;
          chunk.transcript ??= '[Error: $errorStr]';
          await _repository.updateChunk(chunk);
          return false;
        }

        // Apply exponential backoff delay for transient errors
        chunk.retryCount = attempt;
        await _repository.updateChunk(chunk);

        print('Retrying in $backoffSeconds seconds...');
        await Future.delayed(Duration(seconds: backoffSeconds));
        backoffSeconds = (backoffSeconds * 2).clamp(5, 60); // Growth: 5s, 10s, 20s, 40s, 60s
      }
    }

    return false;
  }

  /// Runs privacy-compliant clean up, deleting all audio chunk files on disk
  /// that are older than 24 hours (irrespective of whether they transcribed successfully).
  Future<void> run24HourAutoPurge() async {
    try {
      final chunks = await _repository.getAllChunks();
      final now = DateTime.now();
      int purgedCount = 0;

      for (final chunk in chunks) {
        final age = now.difference(chunk.createdAt);
        if (age.inHours >= 24) {
          final file = File(chunk.filePath);
          if (await file.exists()) {
            await file.delete();
            purgedCount++;

            // If it was still pending or processing, mark as failed due to privacy purge
            if (chunk.status == 'PENDING' || chunk.status == 'PROCESSING') {
              chunk.status = 'FAILED';
              chunk.transcript = '[Audio purged due to 24-hour privacy compliance before transcription finished]';
              await _repository.updateChunk(chunk);
            }
          }
        }
      }
      print('Auto-purge: Cleaned up $purgedCount old recording files.');
    } catch (e) {
      print('Error during 24-hour auto-purge: $e');
    }
  }
}
