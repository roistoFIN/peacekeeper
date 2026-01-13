# Development Guide: Peacekeeper

This document explains how to set up the development environment for the Peacekeeper project.

## 1. Prerequisites

- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install) (3.0+)
- **Dart SDK**: Included with Flutter.
- **Python 3.10+**: For the backend.
- **Google Cloud CLI**: Installed and authenticated.
- **Firebase CLI**: `npm install -g firebase-tools`

## 2. Frontend Setup (Flutter)

1.  **Install dependencies**:
    ```bash
    cd src/frontend
    flutter pub get
    ```
2.  **Environment Configuration**:
    The app automatically switches backends based on the platform:
    - **Chrome (Web):** Connects to `localhost:8000` (Local Python Server).
    - **Android/iOS:** Connects to `https://peacekeeper-backend-xyz.a.run.app` (Cloud Run).

3.  **Run locally**:
    ```bash
    # Run on Chrome (uses local backend)
    flutter run -d chrome

    # Run on Android (uses Cloud backend)
    flutter run -d <device_id>
    ```

## 3. Backend Setup (FastAPI)

1.  **Navigate to backend directory**:
    ```bash
    cd src/backend
    ```

2.  **Create Virtual Environment**:
    ```bash
    python -m venv venv
    source venv/bin/activate
    ```

3.  **Install Dependencies**:
    ```bash
    pip install -r requirements.txt
    ```

4.  **Database Seeding (CRITICAL)**:
    You must populate Firestore with the NVC vocabulary and Safety Rules.
    ```bash
    # Ensure you are authenticated with GCP
    gcloud auth application-default login
    
    # Run the seed script
    export GOOGLE_CLOUD_PROJECT=peacekeeper-483320
    python seed_data.py
    ```

5.  **Run Server Locally**:
    ```bash
    uvicorn app.main:app --reload
    ```
    The server runs at `http://127.0.0.1:8000`.

## 4. Firebase & App Check

- **Local Development:** App Check is disabled for `localhost` to prevent ReCAPTCHA errors.
- **Android Testing:** Ensure your SHA-256 fingerprint is registered in the Firebase Console.

## 5. Troubleshooting

- **"Validation rules missing":** You forgot to run `seed_data.py` or your local server is outdated. Restart `uvicorn`.
- **"Ad failed to load":** Ensure your device ID is added to `AdService.dart` or use a specialized Test Device.
