## System Architecture (Cloud-Native)

This architecture is optimized for scalability and performance. The application is designed to guide a structured process where cognitive load is minimized during active conflict. 

### Tech Stack
* Frontend: Flutter (iOS & Android). Enables a unified user experience and rapid development cycles.
* Backend API: Google Cloud Run (Docker container). Handles the complex "NVC-lite" logic and message filtering to prevent impulsive language. 
* Real-time Database: Firestore. Manages synchronization between devices without the need for persistent WebSocket connections.
* Authentication: Firebase Anonymous Auth. Enables session-based identification without requiring user accounts for v0.1. 

### Architectural Layers
* Orchestration Layer (Firestore): Manages the state machine of the conflict session (e.g., STATUS: REGULATION, STATUS: EXPRESSION_PHASE). 
* Logic Layer (Cloud Run + Gemini): Uses Gemini 2.5 Flash Lite to neutralize observations, predict feelings/needs, and generate role-reversed reflections for the listener.
* Safety Layer (Offensive Gate): Gemini acts as a strict validator in Steps 1 and 4. If input is judgmental or demanding, the "Next" button is disabled until a neutral AI suggestion is accepted.
