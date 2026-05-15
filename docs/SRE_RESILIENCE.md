# SRE and System Resilience

EchoScript is designed for 24/7 reliability in mission-critical environments. This document details the strategies used to ensure system uptime and data integrity.

## 1. Zero-Gap Recording Resilience
The recording engine must operate without interruption for days or weeks.

- **Dual-Sink Handover:** During chunk rotation, the system pre-allocates the next file and `IOSink` before finalizing the current one. This ensures that the PCM stream is never dropped by the recorder.
- **Wakelock Protection:** `WakelockPlus` is enabled during recording to prevent the OS from suspending the CPU, which would lead to capture gaps.
- **Isolate Recovery:** The background service is configured to auto-restart if terminated by the OS (platform-dependent).

## 2. Memory Management (Zero-Heap Policy)
To prevent OOM (Out of Memory) crashes on mobile devices, the system avoids loading large audio files into memory.

- **Streaming Multipart Uploads:** The `TranscriptionService` uses a streaming `FormData` approach. Audio data is read chunk-by-chunk from the disk and written directly to the network socket.
- **Gemini Files API:** By utilizing the Files API (`v1beta`), we upload once and process by reference, reducing the number of heavy network operations.

## 3. Network and API Resilience
Network connectivity is expected to be intermittent.

- **Exponential Backoff:** If the Gemini API returns a `429` (Rate Limit) or `503` (Service Unavailable), the system schedules a retry. The delay increases exponentially (`2^retryCount`) to avoid hammering the service.
- **Persistent Queue:** The transcription status is stored in Isar. If a device loses internet or power, the queue persists and will resume processing pending chunks upon the next successful service start.

## 4. Atomic Data Integrity
All status updates for `AudioChunk` objects are performed within Isar transactions. This ensures that if the app is killed mid-operation, the database remains in a consistent state (e.g., a chunk is either `Transcribing` or `Failed`, but never in an undefined state).
