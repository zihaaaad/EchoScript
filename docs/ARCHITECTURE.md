# System Architecture

EchoScript follows the Clean Architecture pattern, dividing the system into three distinct layers to ensure modularity, testability, and maintainability.

## 1. Presentation Layer
- **Flutter Framework:** Utilized for all UI components.
- **Riverpod 2.x:** Implemented for state management. It provides compile-time safety and ensures that the UI isolate remains reactive while the background isolate handles hardware tasks.
- **MVVM Pattern:** ViewModels (Providers) manage the transformation of domain data for presentation.

## 2. Domain Layer
- **Models/Entities:** `AudioChunk` and `AppSettings`.
- **Logic:** Business rules including search tokenization, chunk duration logic, and concurrency limits.
- **Repository Interfaces:** Defines the contracts for data access, abstracting the specific implementation (Isar, SecureStorage) from the business logic.

## 3. Data Layer
- **Isar Database:** A NoSQL database used for persistent metadata and transcription storage. It supports synchronous and asynchronous transactions.
- **FlutterSecureStorage:** Used for OS-level encryption of sensitive data (API keys).
- **Background Service:** Implements the `FlutterBackgroundService` to manage the audio capture isolate.
- **Data Sources:** 
    - `RecordingService`: Interacts with hardware audio APIs.
    - `TranscriptionService`: Manages network requests to the Gemini API.

## 4. Intersystem Communication
Communication between the UI and background isolates is managed via the `ServiceInstance.invoke` and `service.on` event stream mechanism provided by the background service package.
