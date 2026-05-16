# Contributing to EchoScript

We welcome contributions! To maintain the quality and reliability of EchoScript, please follow these guidelines.

## Clean Architecture Standards
All new features must adhere to our 3-layer architecture:
*   **Domain:** Entities and Repository Interfaces. No platform-specific imports.
*   **Data:** API implementations, Local DB (Isar), and Service logic.
*   **Presentation:** UI screens, widgets, and Riverpod providers.

## Coding Standards
*   **Immutability:** Use `final` for variables whenever possible.
*   **Asynchrony:** Always `await` futures or use `unawaited()` explicitly for background tasks.
*   **Naming:** Follow the [official Dart style guide](https://dart.dev/guides/language/effective-dart/style).
*   **Linting:** Your code must pass `flutter analyze` with zero warnings before submission.

## Pull Request Process
1.  **Branching:** Create a feature branch from `main` (e.g., `feat/audio-visualizer`).
2.  **Testing:** Add unit tests for any new logic in the `test/` directory.
3.  **Documentation:** Update `docs/API_REFERENCE.md` if public methods are changed.
4.  **Review:** All PRs require at least one approval from the core team.

## Automated Checks
Every PR triggers our GitHub Actions CI pipeline which runs:
*   Static analysis
*   Unit tests
*   Build verification
