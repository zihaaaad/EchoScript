class AppConstants {
  AppConstants._();

  // Minimum required disk space in bytes (500 MB)
  static const int minRequiredDiskSpace = 500 * 1024 * 1024;

  // Max retry limit for transcription
  static const int maxRetryCount = 5;

  // Background audio recording chunk interval defaults
  static const int defaultChunkIntervalMinutes = 30;

  // Foreground notification channels details
  static const String notificationChannelId = 'echoscript_background';
  static const String notificationChannelName = 'EchoScript Background Service';
  static const int notificationId = 888;

  // Secure storage keys
  static const String secureApiKeyName = 'gemini_api_key';

  // Supported Gemini Models
  static const String modelFlash = 'gemini-1.5-flash';
  static const String modelPro = 'gemini-1.5-pro';

  // Default Settings
  static const String defaultSystemPrompt = 
      'You are a precise meeting transcriber. Transcribe this audio recording verbatim, maintaining proper paragraphs, punctuation, and capitalization.';
}
