# 🎙️ EchoScript: Enterprise Audio Intelligence

[![EchoScript CI/CD](https://github.com/zihaaaad/EchoScript/actions/workflows/main.yaml/badge.svg)](https://github.com/zihaaaad/EchoScript/actions/workflows/main.yaml)
[![Release](https://img.shields.io/github/v/release/zihaaaad/EchoScript?color=00C2FF&style=flat-square)](https://github.com/zihaaaad/EchoScript/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-7000FF.svg?style=flat-square)](LICENSE)
[![Platform: Android | iOS](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-white?style=flat-square&logo=flutter)](https://flutter.dev)

**EchoScript** is a high-fidelity, enterprise-grade 24/7 audio recording and AI transcription platform. Built with a "Stealth-Tech" aesthetic and powered by Gemini 1.5 Pro, it transforms ambient audio into structured, actionable intelligence with zero data loss.

---

## ⚡ Core Pillars

### 💠 Intelligence Unit (UI/UX)
- **Figma-Fidelity Design:** A deep-black/graphite palette with Neon Cyan accents.
- **Glassmorphism UI:** Frosted glass cards and animated depth layers.
- **Real-time Monitoring:** Tabular time readouts and live status blinking indicators.

### 🎧 Precision Audio Engine
- **24/7 Reliability:** 30-minute automated chunking cycles for infinite recording.
- **Software Amplification:** Integrated DSP for Microphone Gain adjustment (-12dB to +24dB).
- **Background Persistence:** Hardened Android Foreground Service (Microphone type) with `WAKE_LOCK`.

### 🧠 Gemini AI Orchestration
- **Gemini 1.5 Integration:** Leveraging Google's latest models (Pro & Flash) for human-level accuracy.
- **Offline Queue:** Isar-powered NoSQL database manages a robust transcription pipeline.
- **Auto-Purge Logic:** Local audio is automatically deleted only after successful transcription and verification.

---

## 🏗️ Architecture

EchoScript follows **Clean Architecture** principles to ensure enterprise scalability:

- **Presentation:** Riverpod (MVVM) for reactive, high-performance UI state.
- **Domain:** Pure business logic and entity-based models.
- **Data:** Isar (Local Storage), Gemini API (Remote), and Flutter Sound (Hardware abstraction).

---

## 🚀 Getting Started

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/zihaaaad/EchoScript.git
    ```
2.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Configure API Key:**
    - Open the app.
    - Navigate to **Configuration**.
    - Enter your **Gemini API Key** from [Google AI Studio](https://aistudio.google.com/).
4.  **Run Application:**
    ```bash
    flutter run --release
    ```

---

## 🛠️ Tech Stack
- **Framework:** Flutter (3.x)
- **State Management:** Riverpod 2.5
- **Database:** Isar 3.x (NoSQL)
- **Audio:** Flutter Sound
- **Intelligence:** Google Generative AI (Gemini 1.5)
- **CI/CD:** GitHub Actions (Automated SemVer & Release Pipeline)

---

## 📄 Documentation
Comprehensive technical guides, API details, and architectural mappings are available in the [Project Wiki](https://github.com/zihaaaad/EchoScript/wiki).

---

<p align="center">
  Built with ❤️ for High-Reliability Environments.
</p>
