# Peacekeeper: Couples Coach

**Status: Version 0.1 (MVP Ready)**

Peacekeeper is a professional conflict coaching application designed to help individuals and couples de-escalate arguments in real-time. By leveraging established psychological frameworks and Generative AI, it lowers the cognitive load during active conflict, enabling safer and more constructive communication.

## Core Features (v0.1 Implemented)

### 🆘 SOS Mode (Shared Session)
A synchronized "two phones, one conflict" session.
- **Real-time Sync:** Uses Firebase Firestore to coordinate turns between devices.
- **Regulation Phase:** A shared 60-second breathing exercise to down-regulate the nervous system.
- **Turn-Taking:** Enforces structured speaking and listening roles to prevent interruption.

### 🧘 Solo Mode (Self-Guided)
A private flow for individuals to process their thoughts before or after a difficult conversation.
- **Guided Expression:** Walks you through Observation, Feeling, Need, and Request (NVC framework).
- **Auto-Closing:** Automatically summarizes your insights without waiting for a partner.

### 🛡️ Safety & AI Coaching
- **Violent Language Blocking:** Real-time client-side validation blocks blame patterns ("You always...") and violent vocabulary.
- **AI NVC Translator (Premium):** Powered by **Gemini 2.5 Flash Lite**, it suggests neutral, fact-based observations and universal human needs.
- **Empathetic Reflection:** Generates AI-powered reflection statements for the listener to ensure the speaker feels heard.

## Technology Stack

- **Frontend:** Flutter (Android/iOS/Web)
- **Backend:** Python (FastAPI) on Google Cloud Run
- **Database:** Firebase Firestore (Real-time State Machine)
- **AI Engine:** Vertex AI (Gemini 1.5 Flash)
- **Safety:** Local Regex + Remote AI Guardrails

## Documentation

- [**Deployment Guide**](docs/DEPLOYMENT.md): Instructions for building the Android APK and deploying the Backend.
- [**System Architecture**](docs/architecture/systems-design.md): Detailed diagrams of the 5-phase session flow and cloud infrastructure.
- [**AI Integration**](docs/architecture/ai-integration.md): How we use LLMs safely and privately.
- [**Development Guide**](DEVELOPMENT.md): Setup instructions for contributors.

## Project Structure

```
/
├── src/frontend/       # Flutter Application
├── src/backend/        # FastAPI Service & Seed Scripts
├── docs/               # Architecture, Requirements, Roadmap
└── infrastructure/     # Terraform / IaC (Future)
```

## License
Proprietary. All rights reserved.