# EchoScript Operations Manual

This document provides technical specifications and operational requirements for the EchoScript system.

## 1. Architectural Overview
EchoScript is built on Clean Architecture principles, ensuring separation of concerns and testability.

### 1.1 Data Layer
- **Isar Database:** Manages all persistent metadata. Transactions are atomic to prevent data corruption during process termination.
- **Secure Storage:** Utilizes `FlutterSecureStorage` for AES encryption of API keys at the OS level.
- **Background Isolates:** The recording and transcription logic runs in a dedicated isolate to prevent UI jank and ensure 24/7 capture.

### 1.2 Domain Layer
- **Entities:** `AudioChunk` and `AppSettings` represent the core data structures.
- **Logic:** Includes the search tokenization and retry backoff calculations.

### 1.3 Presentation Layer
- **State Management:** Riverpod 2.x is used for compile-time safe state distribution.
- **UI:** Designed for high-contrast "OLED Black" visibility.

## 2. Audio Capture Pipeline
The capture pipeline is designed for "Zero-Gap" operation.

### 2.1 Sink Swapping
The `RecordingService` implements a proactive sink-swapping algorithm. It opens a secondary `IOSink` before the primary sink is finalized, reducing handover latency to under 50ms.

### 2.2 RIFF/WAV Injection
Completed audio chunks are post-processed to inject correct RIFF/WAV headers based on the actual byte count recorded, ensuring compatibility with standard audio players and the Gemini API.

## 3. Transcription Engine
Transcription is handled asynchronously through a user-tunable worker pool.

### 3.1 Streaming Multipart Uploads
To maintain a flat memory profile, the system uses `Dio` to stream audio data directly from the disk to the Gemini Files API. This prevents RAM exhaustion when processing large (60+ minute) audio segments.

### 3.2 Error Handling and Backoff
The engine monitors for `429` (Rate Limit) and `503` (Service Unavailable) errors. On detection, it implements an exponential backoff strategy (`2^retryCount` minutes), ensuring the capture engine remains unaffected by network or API congestion.

## 4. Privacy and Data Lifecycle
- **Local Persistence:** Audio data is stored in the application's temporary directory, bypassing OS-level cloud synchronization.
- **Purge Protocol:** Audio files are automatically deleted upon successful transcription or after 24 hours to ensure local storage hygiene and user privacy.

---
Release Version: 1.1.0 | Project Lead: Zihad Hasan
