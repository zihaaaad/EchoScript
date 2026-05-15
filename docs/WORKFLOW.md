# Intelligence Workflow: The Lifecycle of an Audio Chunk

EchoScript ensures "Zero-Gap" intelligence by processing audio through five distinct stages of the rotation engine.

## 🟢 Stage 1: PCM Capture (Active)
- **Engine:** `RecordingService`
- **Logic:** Audio is captured in 16-bit PCM format and streamed directly to a file sink.
- **Isolate:** Runs in a persistent background isolate with Wakelock active.

## 🟠 Stage 2: Gapless Rotation
- **Trigger:** Dynamic Timer (1–60 minutes).
- **Handover:** A new `IOSink` is opened before the old one is closed.
- **Latency:** Handover is achieved in under 50ms, ensuring no audible gaps in the capture stream.

## 🔵 Stage 3: Finalization
- **Logic:** The `RecordingService` injects the RIFF/WAV header into the completed chunk.
- **Persistence:** The `AudioChunk` status in Isar transitions from `Recording` to `Pending`.

## 🟣 Stage 4: AI Transcription (Streaming)
- **Engine:** `TranscriptionService`
- **Logic:** Files are uploaded to the Gemini Files API.
- **Zero-Heap:** The multipart stream bypasses RAM buffering, preventing crashes on hour-long segments.
- **Concurrency:** Managed by a user-tunable worker pool (1–5 units).

## ⚪ Stage 5: Archive & Purge
- **Persistence:** Transcription text is tokenized for full-text search.
- **Purge:** The local `.wav` file is deleted from `getTemporaryDirectory()` to save space and ensure privacy.
- **Final Status:** `Completed`.
