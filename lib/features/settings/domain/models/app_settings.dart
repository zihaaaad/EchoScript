import 'package:isar/isar.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = 0; // Singleton pattern for settings

  // Gemini API Key is stored in FlutterSecureStorage for security
  String geminiModel = 'gemini-1.5-flash';
  double audioGainDb = 0.0;
  String systemPrompt = 'Transcribe the following audio precisely.';
  bool isRecordingActive = false;
  DateTime? recordingStartTime;
  int aiConcurrencyLimit = 2;
  int chunkDurationMinutes = 30;
}
