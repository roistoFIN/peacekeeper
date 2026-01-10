# Peacekeeper: Couples Coach

Peacekeeper is a professional conflict coaching application designed to help individuals and couples de-escalate arguments in real-time. By leveraging established psychological frameworks and Generative AI, it lowers the cognitive load during active conflict, enabling safer and more constructive communication.

## Core Features

- **SOS Mode (Shared):** A synchronized "two phones, one conflict" session. Guides couples through physiological regulation, structured expression, and empathetic reflection.
- **Solo Mode (Self-Guide):** A guided process for individuals to structure their thoughts and feelings before or after a difficult conversation.
- **AI-Enhanced Coaching:** Powered by Gemini 2.5 Flash Lite to neutralize judgmental language, suggest core emotions, and identify universal human needs.
- **Scientific Basis:** Built on the Gottman Method, Polyvagal Theory, Emotionally Focused Therapy (EFT), and Nonviolent Communication (NVC).
- **In-App Feedback:** Integrated rating and feedback system to continuously improve the coaching experience.

## Tech Stack

- **Frontend:** Flutter (iOS, Android, Web)
- **Backend:** FastAPI (Python) on Google Cloud Run
- **AI:** Vertex AI (Gemini 2.5 Flash Lite)
- **Database/Auth:** Firebase Firestore & Anonymous Auth
- **Monetization:** RevenueCat (Subscriptions) & Google AdMob (Ads)

## Project Structure

- `src/frontend`: Flutter application codebase.
- `src/backend`: FastAPI server handling AI logic and content.
- `docs/`: Comprehensive architecture and requirement documentation.

## Documentation Links

- [Functional Requirements](docs/requirements/functional.md)
- [System Architecture](docs/architecture/systems-design.md)
- [Deployment Guide](docs/DEPLOYMENT.md) - **New!** Instructions for Cloud Run & Android APK.
- [Testing Guide](TESTING.md) - How to run automated tests.

## Status: Version 0.1+ (Development)
The application is currently in active development. AI endpoints are fully functional, and monetization paths (Ads/Premium) are integrated.
