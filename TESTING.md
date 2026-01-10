# Testing Guide

This project contains automated tests for both the Backend (FastAPI) and Frontend (Flutter).

## Backend Tests

The backend tests cover:
- **Unit Tests:** Parsing logic and helpers.
- **Integration Tests:** API endpoints (with mocked Vertex AI).

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

Expected output:
```
tests/test_main.py ....                                                  [100%]
4 passed in 0.xxs
```

---

## Frontend Tests

The frontend tests cover:
- **Widget Tests:** UI rendering and basic interaction (StartScreen, etc.).

### Prerequisites
1. Navigate to the frontend directory:
   ```bash
   cd src/frontend
   ```

### Running Tests
Run all tests with:
```bash
flutter test
```

To run a specific test file:
```bash
flutter test test/start_screen_test.dart
```
