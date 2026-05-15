# Contributor Guidelines: Enterprise Standards

To maintain EchoScript as a top-tier intelligence tool, all contributors must adhere to the following protocols.

## 1. Branching & Commit Strategy
- **Pattern:** `feature/description`, `fix/description`, or `chore/description`.
- **Versioning:** Semantic Versioning (SemVer) 2.0.0.
  - **Major:** Architectural changes or breaking API shifts.
  - **Minor:** New features (e.g., dynamic chunk duration).
  - **Patch:** Bug fixes and performance tuning.

## 2. Coding Standards
- **Linting:** Must pass `flutter analyze` with zero warnings.
- **Testing:** New features require a corresponding `widget_test.dart` or unit test.
- **Architecture:** Strictly follow **Clean Architecture**. Do not leak Data layer logic (e.g., Isar specific queries) into the Presentation layer.

## 3. Security Mandate
- **No Plaintext Keys:** Never print API keys or user data to the console.
- **No Cloud Sync:** Always use `getTemporaryDirectory()` for audio chunks to prevent OS-level cloud syncing.
- **Attribution:** All new files must include the author header:
  `// (c) 2026 Zihad Hasan | EchoScript Intelligence Unit`

---
*By contributing, you agree to uphold the As-Sunnah Foundation AI Team standards.*
