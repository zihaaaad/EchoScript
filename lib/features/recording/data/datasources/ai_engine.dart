import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/constants.dart';

class AiEngine {
  final FlutterSecureStorage _secureStorage;

  AiEngine(this._secureStorage);

  Future<String?> _getApiKey() async {
    return await _secureStorage.read(key: AppConstants.secureApiKeyName);
  }

  /// Uploads local WAV audio to the Gemini Files API.
  /// Returns a Map containing:
  /// - 'uri': The Gemini file URI (to pass to generateContent)
  /// - 'name': The Gemini file resource name (to delete the file later)
  Future<Map<String, String>> uploadAudioFile(File file) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API Key is not configured. Please add it in Settings.');
    }

    final uploadUrl = Uri.parse('https://generativelanguage.googleapis.com/upload/v1beta/files?key=$apiKey');
    
    final request = http.MultipartRequest('POST', uploadUrl);
    request.headers['X-Goog-Upload-Protocol'] = 'multipart';
    request.headers['X-Goog-Upload-Command'] = 'upload, finalize';
    request.headers['X-Goog-Upload-Header-Content-Length'] = file.lengthSync().toString();
    request.headers['X-Goog-Upload-Header-Content-Type'] = 'audio/wav';

    final metadata = jsonEncode({
      'file': {
        'displayName': 'echoscript_${DateTime.now().millisecondsSinceEpoch}',
        'mimeType': 'audio/wav',
      }
    });

    request.files.add(http.MultipartFile.fromString(
      'metadata',
      metadata,
      contentType: MediaType('application', 'json'),
    ));

    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType('audio', 'wav'),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Failed to upload file to Gemini (HTTP ${response.statusCode}): ${response.body}');
    }

    final responseData = jsonDecode(response.body);
    final fileUri = responseData['file']['uri'] as String;
    final fileName = responseData['file']['name'] as String; // format: files/xxxxxx
    
    return {
      'uri': fileUri,
      'name': fileName,
    };
  }

  /// Transcribes audio from an uploaded Gemini file URI.
  Future<String> transcribe(String fileUri, String modelName, String systemPrompt) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Gemini API Key is not configured.');
    }

    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
    );

    final response = await model.generateContent([
      Content.multi([
        FilePart(Uri.parse(fileUri)),
        TextPart('Transcribe the audio recording exactly.'),
      ])
    ]);

    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw Exception('Transcription returned empty response.');
    }

    return text;
  }

  /// Deletes a file from Gemini storage using the Files API.
  Future<void> deleteRemoteFile(String fileName) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) return;

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/$fileName?key=$apiKey');
    try {
      final response = await http.delete(url);
      if (response.statusCode != 200) {
        // Log failure but don't crash
        print('Warning: Failed to delete remote Gemini file $fileName (HTTP ${response.statusCode})');
      }
    } catch (e) {
      print('Warning: Error deleting remote file: $e');
    }
  }
}
