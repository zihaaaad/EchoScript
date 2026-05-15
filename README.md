# EchoScript: Enterprise Audio Intelligence

**EchoScript** is a mission-critical, high-fidelity background audio capture and concurrent AI transcription engine. Engineered for professional environments, it provides seamless, 24/7 intelligence gathering with human-level accuracy powered by Google Gemini 1.5.

## 🚀 Core Value Proposition
- **Zero-Gap Reliability:** Advanced double-buffered PCM16 streaming ensuring not a single syllable is lost during rotation.
- **Concurrent AI Processing:** Dynamic worker pool management for real-time transcription of 30-minute audio chunks.
- **Strategic Privacy:** On-device secure credential management via Android Keystore/iOS Keychain and automated local data lifecycle.
- **Strategic Clarity UX:** A minimalist, high-contrast "OLED Black" interface designed for maximum signal and zero distraction.

## 🛠️ Architecture & Stack
- **Framework:** Flutter (Mobile)
- **State Management:** Riverpod 2.x (Explicit Dependency Injection)
- **Persistence:** Isar NoSQL (Transactional ACID compliance)
- **AI Engine:** Google Gemini 1.5 (Pro & Flash)
- **Design:** "Strategic Clarity" (2026 Professional Standard)

## 📦 Deployment & Setup
1. **Repository Synchronization:**
   ```bash
   git clone https://github.com/zihaaaad/EchoScript.git
   flutter pub get
   ```
2. **AI Protocol Activation:**
   - Secure a Gemini API Key from the [Google AI Studio](https://aistudio.google.com/).
   - Input the key into the encrypted vault within the app's **Control Center**.
3. **Execution:**
   ```bash
   flutter run --release
   ```

## 📊 Technical Documentation
Comprehensive architectural maps, SRE-compliant retry logic specifications, and UX research notes are available in the [Project Wiki](https://github.com/zihaaaad/EchoScript/wiki).

---
*Enterprise Intelligence. Redefined.*
