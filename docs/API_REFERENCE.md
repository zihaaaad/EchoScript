# API Reference: Intelligence Unit & Gemini Integration

EchoScript interacts with the Google Gemini API using a high-efficiency streaming protocol designed for 24/7 autonomous operation.

## 1. Authentication Protocol
- **Storage:** API Keys are stored in OS-level **Secure Storage** (Android Keystore / iOS Keychain).
- **Retrieval:** The `TranscriptionService` fetches the key just-in-time for each worker thread.
- **Safety:** Keys are never persisted in plain-text databases or printed in system logs.

## 2. Gemini Files API Integration (Streaming)
EchoScript uses the `v1beta` Files API to handle large audio files without RAM buffering.

- **Endpoint:** `https://generativelanguage.googleapis.com/upload/v1beta/files`
- **Method:** `POST` (Multipart Streaming)
- **Lifecycle:**
  1. Audio is recorded to a local `.wav` chunk.
  2. `Dio` streams the file to Gemini's storage.
  3. A temporary `fileUri` is returned.
  4. The model processes the `fileUri` reference directly.

## 3. Intelligent Rate Limiting
The system handles `429 (Rate Limit)` and `503 (Overloaded)` errors using exponential backoff:
- **Retry Schedule:** 1 min, 2 min, 4 min, 8 min... (up to 3 retries).
- **Persistence:** Retry status is saved in Isar, allowing tasks to resume after service restarts.
