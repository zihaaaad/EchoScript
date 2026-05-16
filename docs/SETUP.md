# EchoScript Developer Setup

Follow these steps to set up the EchoScript development environment on your local machine.

## Prerequisites
*   **Flutter SDK:** 3.19.0 or higher.
*   **Dart SDK:** 3.3.0 or higher.
*   **Android Studio / Xcode:** For mobile platform compilation.
*   **Gemini API Key:** Obtain one from the [Google AI Studio](https://aistudio.google.com/).

## Initial Setup

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/your-org/echoscript.git
    cd echoscript
    ```

2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Generate Code (Isar/Riverpod):**
    EchoScript uses `build_runner` for Isar schemas and JSON serialization.
    ```bash
    flutter pub run build_runner build --delete-conflicting-outputs
    ```

## Platform-Specific Notes

### Android
*   The app requires `RECORD_AUDIO` and `FOREGROUND_SERVICE` permissions.
*   Ensure your `minSdkVersion` is at least 21.

### iOS
*   Microphone access requires a valid `NSMicrophoneUsageDescription` in `Info.plist` (already configured).
*   Background recording requires `UIBackgroundModes` set to `audio` (already configured).

## Running Tests
To verify your setup, run the comprehensive test suite:
```bash
flutter test
```

## Troubleshooting
*   **Isar initialization error:** If you see `isar.dll` missing on Windows during tests, use the mocked repository tests which isolate the logic from the native binary.
*   **Background service not starting:** Ensure you have accepted the microphone permission and disabled battery optimization for the app.
