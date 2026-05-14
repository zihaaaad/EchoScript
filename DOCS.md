# EchoScript - Enterprise Documentation

EchoScript is a robust, 24/7 audio recording and transcription platform designed for high-reliability environments. This documentation provides a technical overview of the system's internal mechanics and operational procedures.

## 🏗️ Architectural Blueprint
EchoScript is engineered using **Clean Architecture** to ensure that business logic remains decoupled from external frameworks like Flutter or Isar.

### Layer Responsibility:
- **Presentation Layer (`lib/features/*/presentation`)**: Uses Riverpod for state management. Ensures the UI is a pure reflection of the underlying state.
- **Domain Layer (`lib/features/*/domain`)**: Contains pure Dart models and use-cases. This is the heart of the application.
- **Data Layer (`lib/features/*/data`)**: Implements repositories and datasources. Handles Isar database queries, Hardware Microphone access, and Gemini API calls.

---

## ⏺️ Recording Engine & Chunking
To support 24/7 recording without memory overflow or file corruption, EchoScript employs a **Rotational Chunking Strategy**:
1.  **30-Minute Cycle:** Every 30 minutes, the `RecordingService` automatically stops the current stream, saves the file, and immediately starts a new one.
2.  **Gapless Transition:** The switch happens in milliseconds to ensure no spoken words are lost during rotation.
3.  **WAKE_LOCK & Foreground Service:** The system utilizes `wakelock_plus` and an Android Foreground Service to prevent the OS from killing the process during deep sleep.

---

## 🤖 AI Transcription Pipeline
The transcription process is asynchronous and resilient:
1.  **Local Queue:** Finished chunks are marked as `pending` in the Isar database.
2.  **Background Processor:** A background timer checks the queue every 60 seconds.
3.  **Gemini 1.5 Integration:** Audio is transmitted directly to Google's Gemini API for high-fidelity transcription.
4.  **Hardware DSP:** If specified in settings, the system applies a software-based Gain multiplier to the audio stream before processing, enhancing clarity for distant voices.

---

## 🔒 Security & Data Privacy
- **Local Sovereignty:** Transcription happens between your device and Google's servers. EchoScript does not use a secondary proxy or "middleman" server.
- **Auto-Purge Strategy:** To protect user privacy and save disk space, the local `.aac` audio file is **permanently deleted** from the device as soon as a successful transcription is received and stored in the database.

---

## 📦 Deployment & Versioning
EchoScript uses a sophisticated CI/CD pipeline:
- **Automated SemVer:** Every push to `main` triggers a build that injects the GitHub Run ID as the build number.
- **Artifacts:** Releases include both a universal **APK** for easy installation and an **AppBundle (AAB)** for optimized Play Store distribution.
- **Vaulting:** The `HistoryPage` serves as a secure vault where all past transcriptions are indexed and searchable.

---

*For further technical support or architectural inquiries, please consult the internal team or review the source code in `lib/core/`.*
