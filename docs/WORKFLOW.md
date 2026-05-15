# Intelligence Workflow: Audio Chunk Lifecycle

This document describes the lifecycle of an audio chunk within the EchoScript rotation engine.

## Stage 1: PCM Capture
- **Service:** `RecordingService`
- **Mechanism:** Audio is captured in 16-bit PCM format and written directly to an asynchronous file sink.
- **Execution:** Runs in a persistent background isolate with Wakelock active to ensure zero-drop capture.

## Stage 2: Gapless Rotation
- **Handover:** A secondary file and `IOSink` are initialized before the primary sink is closed.
- **Timing:** Handover latency is optimized to under 50ms.
- **Trigger:** Rotation occurs at user-defined intervals (1–60 minutes).

## Stage 3: Finalization and Header Injection
- **Processing:** RIFF/WAV headers are injected into the finalized `.wav` file.
- **Persistence:** Metadata is updated in Isar, transitioning the chunk to `Pending`.

## Stage 4: Asynchronous Transcription
- **Service:** `TranscriptionService`
- **Protocol:** Multipart streaming to the Gemini Files API.
- **Resource Management:** Bypasses RAM buffering to maintain a flat heap profile.
- **Concurrency:** Tasks are distributed across a user-configurable worker pool.

## Stage 5: Archive and Data hygiene
- **Searchability:** Transcription results are tokenized for full-text search.
- **Privacy:** Local `.wav` files are deleted from temporary storage upon successful transcription.
- **Completion:** Chunk status transitions to `Completed`.
