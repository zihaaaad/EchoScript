# EchoScript: Professional Operations Manual

This document serves as the primary technical specification and operational guide for the **EchoScript** Enterprise Intelligence Engine.

## 1. System Architecture
EchoScript utilizes a **Clean Architecture** model with strict layer separation:
- **Data Layer:** Manages Isar transactions, Secure Storage encryption, and background service isolates.
- **Domain Layer:** Defines the `AudioChunk` and `AppSettings` models with transactional business logic.
- **Presentation Layer:** Implements the "Strategic Clarity" UI using Riverpod for state synchronization.

## 2. Intelligence Pipeline
The pipeline is designed for 24/7 autonomous operation:
1. **Capture:** Double-buffered PCM16 recording with 30-minute rotation.
2. **Finalization:** Automatic WAV header injection and Isar status transition.
3. **Transcription:** Dynamic worker pool (Max Concurrency: 2) with exponential backoff retry logic.
4. **Archive:** Permanent storage in Isar with automated audio source purging upon successful AI processing.

## 3. Security & Privacy
- **Credentials:** Gemini API keys are never stored in the database. They reside in the OS-level **Secure Storage** (Android Keystore / iOS Keychain).
- **Local First:** All audio data remains on-device until transcription, after which it is immediately purged to maintain a zero-footprint archive.

## 4. Operation Protocols
To ensure 24/7 reliability, users must:
1. Provide a valid Gemini API Key in the **Control Center**.
2. Exempt EchoScript from system **Battery Optimization**.
3. Grant "Microphone" and "Notification" permissions.

---
*For internal enterprise use only.*
