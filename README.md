# EchoScript

High-fidelity background audio recording application and concurrent AI transcription engine built with Flutter, Riverpod, Isar NoSQL database, and the Google Gemini API.

---

## Architectural Highlights

- **Persistent Background Recording:** Uses `flutter_background_service` and `wakelock_plus` combined with foreground notifications to sustain continuous audio recording even when the device is locked or minimized.
- **Multilingual AI Transcription:** Integrates `google_generative_ai` (Gemini API) to process audio streams and generate formatted transcripts, structured summaries, and speaker-separated meeting notes.
- **Offline-First Storage:** Powered by the `Isar` high-performance local NoSQL database for instant full-text searching across historical recordings and transcripts with zero cloud latency.
- **Secure Key Storage:** Manages Gemini API keys and credentials locally on the device using platform hardware keystores via `flutter_secure_storage`.
- **PDF Export Suite:** Converts transcripts and structured summaries into styled, printable PDF documents on-device using the `pdf` engine.
- **Reactive State Architecture:** Built with `flutter_riverpod` and code generation (`riverpod_generator`) for strict separation of concerns, testability, and deterministic UI state updates.

---

## Technology Stack

| Layer | Technologies |
| :--- | :--- |
| **Framework & Language** | Flutter 3.x, Dart |
| **State Management** | Flutter Riverpod 2.x, Riverpod Generator |
| **Audio Processing** | flutter_sound, audio_session |
| **Background Processing** | flutter_background_service, flutter_local_notifications, wakelock_plus |
| **AI Engine** | google_generative_ai (Google Gemini API) |
| **Database & Cache** | Isar Database (Fast embedded NoSQL engine) |
| **Security** | flutter_secure_storage (Android Keystore / iOS Keychain) |
| **Document Generation** | pdf, path_provider, share_plus |

---

## Project Structure

```text
lib/
├── core/
│   ├── constants/       # App-wide constants, themes, and styles
│   ├── database/        # Isar schema definitions and database service
│   ├── network/         # HTTP and Gemini API client integrations
│   └── utils/           # Time formatters, permissions, and file helpers
├── features/
│   ├── audio/           # Audio session manager, recorder, and background worker
│   ├── transcription/   # Gemini AI prompt pipelines, chunking, and parser
│   ├── history/         # Recording catalogs, search filters, and detail views
│   └── export/          # PDF generator and system share sheet bridges
├── shared/
│   ├── providers/       # Riverpod global dependency injection
│   └── widgets/         # Reusable UI controls, buttons, and dialogs
└── main.dart            # Application entrypoint and background service initialization
```

---

## Local Development & Setup

### Prerequisites

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Set up Android Studio / VS Code with Flutter and Dart plugins.
3. Obtain a [Google Gemini API Key](https://aistudio.google.com/).

### Setup Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/zihaaaad/EchoScript.git
   cd EchoScript
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run code generation (Isar & Riverpod):**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run on a physical device or emulator:**
   ```bash
   flutter run
   ```
   *(Note: Testing background audio services is recommended on physical hardware).*

---

## Permissions

EchoScript requires the following permissions configured in `AndroidManifest.xml` / `Info.plist`:
- `RECORD_AUDIO`: Required for microphone access.
- `FOREGROUND_SERVICE` & `FOREGROUND_SERVICE_MICROPHONE`: For persistent background recording.
- `WAKE_LOCK`: Prevents CPU sleep during active sessions.
- `POST_NOTIFICATIONS`: Displays active recording status controls in the notification tray.

---

## License

This project is open-source and licensed under the [MIT License](LICENSE).
