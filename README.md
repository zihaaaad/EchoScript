# EchoScript Intelligence Unit

**Version:** 1.1.0  
**Project Lead:** Zihad Hasan

EchoScript is a technical implementation for high-reliability background audio capture and concurrent asynchronous transcription using the Gemini API. The system is designed for persistent 24/7 operation with a focus on data integrity, local-first persistence, and memory-efficient streaming.

## Core Technical Pillars

### 1. Gapless Audio Capture
The system utilizes a dual-sink rotation engine. It manages the handover between IOSink objects in under 50ms, ensuring a continuous capture stream during multi-hour recording sessions. Rotation intervals are user-configurable between 1 and 60 minutes.

### 2. SRE-Hardened Pipeline
- **Memory Management:** Implements multipart streaming via the Gemini Files API, maintaining a flat heap profile by avoiding large buffer allocations.
- **Resilience:** Features an Isar-based persistent queue with exponential backoff (retry logic for 429 and 503 status codes).
- **Process Persistence:** Background isolates are synchronized with WakelockPlus and Foreground Service notifications to maintain activity across Android power profiles.

### 3. Data Architecture
- **Persistence:** Utilizes Isar (NoSQL) for high-performance metadata and transcription storage.
- **Search:** Transcription text is indexed for sub-millisecond full-text search.
- **Privacy:** Implements a 24-hour audio purge protocol and local-first storage in `getTemporaryDirectory()`.

## System Architecture

The project follows a strict Clean Architecture pattern with MVVM state management:

- **Presentation Layer:** Flutter UI with Riverpod for reactive state synchronization.
- **Domain Layer:** Business logic, entities, and repository interfaces.
- **Data Layer:** Isar implementations, Secure Storage for API keys, and background service isolates.

## Deployment and Setup

1. **API Key:** API keys must be stored in the encrypted Control Center (utilizes FlutterSecureStorage).
2. **Permissions:** Requires Microphone and Notification permissions. Battery optimization should be disabled for the EchoScript process to ensure 24/7 stability.
3. **Hardware:** Software gain calibration is available in the Hardware DSP section of the settings.

---
Copyright (c) 2026 Zihad Hasan | As-Sunnah Foundation AI Team
