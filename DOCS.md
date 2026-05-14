# EchoScript Documentation

Welcome to the professional documentation for EchoScript.

## System Architecture
EchoScript is designed using Clean Architecture principles to ensure high maintainability and reliability.

### Core Components
- **Recording Engine:** Manages continuous audio capture in 30-minute segments.
- **Transcription Pipeline:** Asynchronous processing of audio chunks using the Gemini 1.5 API.
- **Persistence Layer:** Uses Isar NoSQL for fast, indexed access to your archive.

## Operational Guide
1. **Background Service:** The app uses an Android Foreground Service to ensure recordings are not interrupted by the system.
2. **Audio Gain:** Software-level gain can be adjusted in settings to improve clarity for distant voices.
3. **Storage Management:** Audio files are automatically purged after successful transcription to optimize device storage.

## Troubleshooting
- **API Errors:** Ensure your Gemini API Key is valid and has sufficient quota.
- **Microphone Access:** Grant the necessary permissions when prompted to enable capture.

For further assistance, please review the source code or contact the project maintainers.
