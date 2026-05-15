# Privacy and Data Governance

EchoScript implements a "Local-First" data strategy to ensure maximum user privacy and data security.

## 1. Local-First Storage
- **Temporary Isolation:** Audio chunks are stored in `getTemporaryDirectory()`. This location is intentionally chosen to bypass standard OS-level cloud synchronization (e.g., iCloud or Google Drive backups).
- **Encrypted Metadata:** While transcription text is stored in Isar, sensitive identifiers and API keys are stored in `FlutterSecureStorage`, which utilizes platform-specific hardware encryption (KeyChain/KeyStore).

## 2. Audio Purge Logic
- **Success Purge:** Upon successful transcription and verification of the result, the corresponding local audio file is immediately deleted from the device.
- **24-Hour Purge:** Any audio chunk older than 24 hours that has not been successfully processed is automatically flagged for deletion to maintain local storage hygiene and minimize the risk of unauthorized data access.

## 3. Transparency and Consent
- **Microphone Access:** EchoScript only activates the microphone when the user explicitly initiates a "Capture" session.
- **Data Transmission:** Only the recorded audio data is transmitted to the Google Gemini API for transcription. No other metadata or user-identifiable information is shared with third-party services.

## 4. Hardware Security
By utilizing OS-level secure storage, the system ensures that API keys are never stored in plain text on the device filesystem, protecting against unauthorized retrieval even if the device is physically compromised.
