# EchoScript Technical Architecture

This document provides a deep dive into the core engines that power EchoScript's enterprise-grade transcription capabilities.

## 1. Gapless Audio Rotation Engine

EchoScript is designed for 24/7 capture. To prevent data loss and manage storage efficiently, the `RecordingService` implements a dual-sink gapless rotation strategy.

### The Mechanism
1.  **Dual-Sink Strategy:** When a chunk duration (default 30 min) is reached, the engine opens a new `IOSink` for the next file *before* closing the previous one.
2.  **Stream Splitting:** Incoming PCM audio bytes are immediately routed to the active sink. During rotation, the stream is seamlessly transitioned to the new file.
3.  **WAV Header Finalization:** Since WAV headers require the total file size (which is unknown until recording ends), EchoScript writes a 44-byte placeholder at the start. Upon rotation, the engine calculates the final byte count and overwrites the placeholder with a valid WAV header using a `RandomAccessFile`.

### Data Flow
`Microphone` → `StreamController` → `Current IOSink` → `Isar (Metadata Tracking)`

---

## 2. Dynamic AI Worker Pool

Transcription is an asynchronous, resource-intensive process. The `TranscriptionService` uses a dynamic pool to manage concurrency and ensure system stability.

### Concurrency Management
*   **Hardware-Aware:** The pool size is controlled by the `aiConcurrencyLimit` setting, allowing users to balance speed with device performance/battery life.
*   **Event-Driven:** The `RecordingManager` watches the Isar database for "Pending" chunks. When a chunk is finalized by the recording engine, the pool is automatically triggered.

### Resilience & Backoff
*   **Exponential Backoff:** If the Gemini API returns a rate limit or network error, the chunk enters a failure state with a retry counter.
*   **Wait Logic:** Retries are scheduled using a `2^retryCount` minutes formula, preventing the app from spamming the API during outages.
*   **Persistence:** The transcription queue survives app restarts and background service reboots because state is tracked in Isar.

---

## 3. Clean Architecture Implementation

EchoScript follows a strict Clean Architecture pattern to ensure testability and maintainability.

*   **Domain Layer:** Contains purely logical definitions (Entities & Repository Interfaces). No dependencies on Isar or Flutter.
*   **Data Layer:** Implements repository interfaces using Isar and provides the actual `RecordingService` and `TranscriptionService`.
*   **Presentation Layer:** OLED-optimized UI built with Riverpod for state management.

### Dependency Flow
`UI (Presentation)` → `Providers (Core)` → `Services (Data)` → `Repositories (Domain)`

---

## 4. Background Service Architecture

EchoScript uses `flutter_background_service` to run a separate Isolate for continuous recording.

*   **Isolate Communication:** The UI and Background isolates communicate via event-based `invoke()` and `on()` methods.
*   **Foreground Service:** On Android, a persistent notification ensures the OS doesn't kill the recording process.
*   **Wakelock:** The service holds a partial wakelock while recording to keep the CPU active while the screen is off.
