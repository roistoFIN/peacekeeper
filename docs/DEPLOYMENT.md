# Deployment Guide: Peacekeeper

This document outlines the steps to deploy the Peacekeeper backend to Google Cloud and build the frontend for release.

## 1. Backend Deployment (Google Cloud Run)

The backend is a containerized FastAPI application managed by Google Cloud Run.

### Prerequisites
- Google Cloud CLI (`gcloud`) installed and authenticated.
- A GCP Project with Billing enabled.

### Deploy Command
Run this from the root of your project:

```bash
cd src/backend
gcloud run deploy peacekeeper-backend \
  --source . \
  --region us-central1 \
  --project peacekeeper-483320 \
  --allow-unauthenticated \
  --set-env-vars GOOGLE_CLOUD_PROJECT=peacekeeper-483320,DEBUG_MODE=false
```

### Environment Variables
- `GOOGLE_CLOUD_PROJECT`: Your GCP Project ID (e.g., `peacekeeper-483320`).
- `DEBUG_MODE`: Set to `false` for production to disable verbose logging and enforce rate limits (if enabled).

### Output
The command will output a URL (e.g., `https://peacekeeper-backend-xyz.a.run.app`).
**Note:** Ensure this URL matches the `_baseUrl` configuration in `src/frontend/lib/services/content_service.dart`.

---

## 2. Frontend Build (Android APK)

To create a downloadable installation package for Android users without using the Play Store.

### Configuration
The app automatically switches API endpoints based on the platform and build mode:
- **Web/Desktop Debug:** Points to `localhost:8000`.
- **Android (All modes):** Points to the production Cloud Run URL (`https://peacekeeper-backend-c7fnii4s3a-uc.a.run.app`) to support testing on physical devices without complex networking.
- **Release Mode:** Points to the production Cloud Run URL.

### App Check & Security
- **Release Builds:** App Check is enabled using `AndroidProvider.playIntegrity`. Ensure your SHA-256 fingerprints are registered in the Firebase Console under App Check.
- **Sideloading:** If sideloading an APK, App Check might fall back to a placeholder token if Play Integrity is unavailable. The app is configured to handle this without crashing.

### Build Command
Run this from the frontend directory:

```bash
cd src/frontend
flutter build apk --release
```

### Locate Output
The installable APK file will be located at:
`src/frontend/build/app/outputs/flutter-apk/app-release.apk`

### Distribution
1. Upload this file to Google Drive, Dropbox, or a web server.
2. Share the link with your testers.
3. Testers must enable "Install unknown apps" in their settings to install it.

---

## 3. Production Checklist

Before sharing the APK publicly:
1. **AdMob:** Replace the Test Ad Unit IDs in `src/frontend/lib/services/ad_helper.dart` with real IDs from your AdMob account.
2. **RevenueCat:** Ensure your RevenueCat project is linked to Google Play Console and the API keys in `revenuecat_helper.dart` are live.
3. **Firestore Rules:** Review your Firestore Security Rules to ensure production data is protected (currently open/anonymous).
