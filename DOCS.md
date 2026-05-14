# EchoScript - Enterprise Audio Intelligence

EchoScript is a robust, 24/7 audio recording and transcription platform designed for high-reliability environments. 

## Architecture
- **Clean Architecture:** Strict separation between Data, Domain, and Presentation layers.
- **MVVM Pattern:** State management handled by Riverpod for reactive and testable UI.
- **Offline First:** Local Isar Database acts as a persistent queue, ensuring no data loss during network outages.

## Core Features
- **Continuous Recording:** 30-minute chunking logic for infinite recording capability.
- **Audio Gain Control:** Software-based gain adjustment from -12dB to +24dB.
- **Gemini AI Integration:** Automated transcription using Google's latest Generative AI models.
- **Background Persistence:** Android Foreground Service with microphone permissions for uninterrupted service.

## Security
- API Keys are stored locally and never transmitted except to the official Gemini API.
- Audio data is purged locally immediately after successful transcription and confirmation.

## Enterprise Versioning Strategy
EchoScript utilizes a dual-layer versioning system for maximum professionalism:
1.  **Semantic Version (SemVer):** Managed in `pubspec.yaml` (e.g., `1.0.0`). This reflects major feature releases and architectural shifts.
2.  **Dynamic Build Number:** Every CI/CD run injects a unique build number (GitHub Run ID) into the final APK and AppBundle. This ensures that every build is unique and traceable back to a specific commit.
3.  **Traceability:** The in-app settings display the full version string (e.g., `v1.0.0+42`), allowing users and support teams to identify the exact build in use.

## Technical Requirements
- Android 8.0+ (Oreo) for stable foreground services.
- Unrestricted Battery Usage permission (recommended).
- Gemini API Key from Google AI Studio.
