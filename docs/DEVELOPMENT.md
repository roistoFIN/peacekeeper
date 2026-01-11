# Development Guide: Peacekeeper: Couples Coach 

This document explains how to set up the development environment for the Peacekeeper project on a new machine.

## 1. Prerequisites

- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK**: Included with Flutter.
- **Android Studio / Xcode**: For mobile development.
- **Google Cloud CLI**: For backend deployment and Firebase integration.
- **Firebase CLI**: `npm install -g firebase-tools`

## 2. Frontend Setup (Flutter)

1.  **Install dependencies**:
    ```bash
    cd src/frontend
    flutter pub get
    ```
2.  **Chromium for Web Testing**:
    If you use Chromium instead of Google Chrome on Linux:
    ```bash
    export CHROME_EXECUTABLE=/usr/bin/chromium
    ```

## 3. Recreating Firebase Configuration

Since sensitive files like `google-services.json` and `firebase_options.dart` are excluded from the repository, you must recreate them for your environment:

1.  **Log in to Firebase**:
    ```bash
    firebase login
    ```
2.  **Activate FlutterFire CLI**:
    ```bash
    dart pub global activate flutterfire_cli
    ```
3.  **Configure Firebase**:
    Run this command in `src/frontend`. It will walk you through selecting your Firebase project and will automatically generate `firebase_options.dart` and the platform-specific JSON/Plist files.
    ```bash
    flutterfire configure
    ```
    *Note: This requires you to have a Firebase project created in the [Firebase Console](https://console.firebase.google.com/).*

## 4. Backend Setup (FastAPI)

1.  **Navigate to backend directory**:
    ```bash
    cd src/backend
    ```

2.  **Create and Activate Virtual Environment**:
    ```bash
    python -m venv venv
    source venv/bin/activate
    ```

3.  **Install dependencies**:
    ```bash
    pip install -r requirements.txt
    ```

4.  **Authenticate GCP (Required for Firebase)**:
    If running natively (not in Docker), you must provide credentials:
    ```bash
    gcloud auth application-default login
    ```

5.  **Run locally**:
    ```bash
    uvicorn app.main:app --reload
    ```
    The server will run at `http://127.0.0.1:8000`.

### 6. Real Device Testing (Android)

When testing on a physical Android device:
1.  **Connectivity:** The app is configured to use the production backend URL for Android by default to bypass local network restrictions.
2.  **App Check Debug Token:**
    - Run the app in debug mode: `flutter run`.
    - Look for the **Firebase App Check debug token** in the `logcat` or console output.
    - Copy this token and add it to the **App Check > Apps > [Your App] > Manage Debug Tokens** section in the Firebase Console.
    - This allows your physical device to bypass App Check during development.

