## System Architecture (Cloud-Native)

This architecture is optimized for the GCP Free Tier and follows a "scale-to-zero" principle to keep beta-phase costs at zero. The application is designed to guide a structured process where cognitive load is minimized during active conflict. 

### Tech Stack
* Frontend: Flutter (iOS & Android). Enables a unified user experience and rapid development cycles.
* Backend API: Google Cloud Run (Docker container). Handles the complex "NVC-lite" logic and message filtering to prevent impulsive language. 
* Real-time Database: Firestore. Manages synchronization between devices without the need for persistent WebSocket connections.
* Authentication: Firebase Anonymous Auth. Enables session-based identification without requiring user accounts for v0.1. 

### Architectural Layers
* Orchestration Layer (Firestore): Manages the state machine of the conflict session (e.g., STATUS: REGULATION, STATUS: EXPRESSION_PHASE). 
* Logic Layer (Cloud Run + Gemini): Uses Gemini 2.5 Flash Lite to neutralize observations, predict feelings/needs, and generate role-reversed reflections for the listener.
* Safety Layer (Offensive Gate): Gemini acts as a strict validator in Steps 1 and 4. If input is judgmental or demanding, the "Next" button is disabled until a neutral AI suggestion is accepted.

### AI Efficiency Model (The 3 Gates)
To maintain the free tier, AI usage is optimized via three layers:
1. **Client-Side Pre-Filtering**: Frontend debounces input (800ms) and enforces character limits (200 chars) to prevent wasteful calls.
2. **Firestore Caching**: AI responses are hashed and cached in Firestore for 10 minutes. Identical requests bypass Gemini entirely.
3. **Backend Rate Limiting**: A Token Bucket algorithm enforces a strict limit (e.g., 5 requests/minute) per user to prevent abuse.