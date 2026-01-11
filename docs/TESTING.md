# Testing Guide

This project maintains automated tests for both the Backend (FastAPI) and Frontend (Flutter).

## Backend Tests

The backend tests cover unit logic (parsers) and integration logic (API endpoints) using mocked Vertex AI responses.

### Prerequisites
1. Navigate to the backend directory:
   ```bash
   cd src/backend
   ```
2. Activate your virtual environment:
   ```bash
   source venv/bin/activate
   ```
3. Install test dependencies:
   ```bash
   pip install pytest httpx
   ```

### Running Tests
Run all tests with:
```bash
pytest tests/
```

---

## Frontend Tests

The frontend tests use `flutter_test` to verify UI navigation and widget composition.

### Key Test Files
- `test/start_screen_test.dart`: Verifies the landing page UI and navigation buttons.
- `test/session_creation_test.dart`: Verifies the flow from SOS button to Session Creation (mocking Firebase).
- `test/widget_test.dart`: A basic smoke test for app initialization.
- `test/safety_service_test.dart`: Verifies the regex logic for detecting blame patterns and offensive language locally.
- `test/layout_test.dart`: Verifies that key screens (e.g., Paywall) render without overflow errors on small devices.

### Mocking Strategy
The tests use a custom `mock.dart` helper to mock:
- **Firebase Core:** Intercepts initialization calls to prevent platform errors.
- **Firebase Auth:** Mocks anonymous sign-in to return a test user.
- **Platform Channels:** Uses `MethodChannel` mocks for compatibility.

### Running Tests
Run all tests with:
```bash
cd src/frontend
flutter test
```

### Known Limitations
- **Firestore:** Deep integration tests involving complex Firestore data streams are currently limited due to the complexity of mocking binary Pigeon streams. These are covered by manual testing (see `docs/DEPLOYMENT.md`).