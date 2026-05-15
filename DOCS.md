# EchoScript: Professional Operations Manual

This document serves as the primary technical specification and operational guide for the **EchoScript** Enterprise Intelligence Engine.

## 1. System Architecture
EchoScript utilizes a **Clean Architecture** model with strict layer separation:
- **Data Layer:** Manages Isar transactions, Secure Storage encryption, and background service isolates. Implements the Gemini Files API streaming protocol.
- **Domain Layer:** Defines the `AudioChunk` (with tokenized search) and `AppSettings` (dynamic configuration) models.
- **Presentation Layer:** Implements the "Strategic Clarity" UI using Riverpod for reactive state synchronization.

## 2. Intelligence Pipeline
The pipeline is designed for 24/7 autonomous operation:
1. **Capture:** Double-buffered PCM16 recording with dynamic rotation (1–60 minutes).
2. **Finalization:** Automatic WAV header injection and Isar status transition (`Pending`).
3. **Transcription:** Dynamic worker pool (User-tunable Concurrency: 1–5) using streaming multipart uploads to minimize heap pressure.
4. **Archive:** Permanent storage in Isar with tokenized transcription words for sub-millisecond keyword searching.

## 3. Configuration & Optimization
Located in the **Control Center**, these parameters allow for environmental calibration:
- **Processor Model:** Toggle between `1.5 Flash` (efficiency) and `1.5 Pro` (complex reasoning).
- **AI Concurrency:** Defines the number of simultaneous transcription workers.
- **Chunk Rotation:** User-defined audio segment length (1–60 mins).
- **Software Gain:** Digital pre-amplification for low-volume environments.

## 4. Security & Privacy
- **Credentials:** Gemini API keys are never stored in the database. They reside in the OS-level **Secure Storage** (Android Keystore / iOS Keychain).
- **Zero-Footprint:** Audio data remains in `getTemporaryDirectory()` to bypass cloud backups and is purged after successful transcription processing.

## 5. Deployment Protocols
To ensure mission-critical reliability:
1. Exempt EchoScript from system **Battery Optimization**.
2. Grant "Microphone" and "Notification" (Background Service) permissions.
3. Use a high-quality external microphone for superior AI reasoning results.

---
*For internal enterprise use only. Release 1.0.1+12*
