import 'package:isar/isar.dart';

part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = 0; // Singleton ID for Isar

  late double gainMultiplier; // 0.25 to 16.0 (represents gain change)

  late int chunkIntervalMinutes; // e.g. 15, 30, 60

  late String systemPrompt;

  late String selectedModel; // 'gemini-1.5-flash', 'gemini-1.5-pro'

  late bool isFirstLaunch;
}
