# EchoScript API Reference

This document outlines the primary service interfaces and methods used within the EchoScript engine.

## 1. RecordingService
`lib/features/recording/data/datasources/recording_service.dart`

The core engine responsible for audio capture and WAV file management.

| Method | Returns | Description |
| :--- | :--- | :--- |
| `init()` | `Future<void>` | Initializes hardware and audio session configuration. |
| `start()` | `Future<void>` | Starts the gapless recording engine and rotation timer. |
| `stop()` | `Future<void>` | Stops recording and finalizes the current audio chunk. |
| `dispose()` | `void` | Releases hardware resources and cancels timers. |

---

## 2. TranscriptionService
`lib/features/recording/data/datasources/transcription_service.dart`

Manages the AI transcription pipeline and Gemini API interactions.

| Method | Returns | Description |
| :--- | :--- | :--- |
| `testApiKey(key, model)` | `Future<bool>` | Validates API key connectivity with a "Ping" prompt. |
| `processQueue()` | `Future<void>` | Triggers the dynamic worker pool to process pending chunks. |
| `purgeOldData()` | `Future<void>` | Removes completed transcriptions older than 24 hours. |

---

## 3. RecordingManager
`lib/features/recording/data/repositories/recording_manager.dart`

Orchestrates the lifecycle between recording and transcription.

| Method | Returns | Description |
| :--- | :--- | :--- |
| `startRecording()` | `Future<void>` | Starts recording and attaches the database event listener. |
| `stopRecording()` | `Future<void>` | Stops recording and runs a final transcription pass. |

---

## 4. PermissionManager
`lib/core/utils/permission_manager.dart`

Handles cross-platform permission requests.

| Method | Returns | Description |
| :--- | :--- | :--- |
| `requestPermissions()` | `Future<bool>` | Requests Microphone, Notification, and Battery Optimization bypass. |

---

## 5. Repositories
`lib/features/recording/domain/repositories/transcription_repositories.dart`

| Interface | Method | Description |
| :--- | :--- | :--- |
| `AudioChunkRepository` | `getPendingChunks(retries)` | Fetches chunks eligible for transcription. |
| `AudioChunkRepository` | `updateChunk(chunk)` | Persists chunk status/transcription updates. |
| `AppSettingsRepository` | `getSettings()` | Retrieves current user configuration. |
