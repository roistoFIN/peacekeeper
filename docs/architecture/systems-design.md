## System Architecture (Cloud-Native)

This architecture is optimized for the GCP Free Tier and follows a "scale-to-zero" principle to keep beta-phase costs at zero. The application is designed to guide a structured process where cognitive load is minimized during active conflict. 

### Tech Stack
* Frontend: Flutter (iOS & Android). Enables a unified user experience and rapid development cycles.
* Backend API: Google Cloud Run (Docker container). Handles the complex "NVC-lite" logic and message filtering to prevent impulsive language. 
* Real-time Database: Firestore. Manages synchronization between devices without the need for persistent WebSocket connections.
* Authentication: Firebase Anonymous Auth. Enables session-based identification without requiring user accounts for v0.1. 

### Architectural Layers
* Orchestration Layer (Firestore): Manages the state machine of the conflict session (e.g., STATUS: REGULATION, STATUS: TURN_A). 
* Logic Layer (Cloud Run): Contains the rules for converting user-selected emotions and needs into NVC-structured sentences. 
* Safety Layer: Blocks profanity and restricts free-text input to prevent further escalation.