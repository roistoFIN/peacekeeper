# Systems Design: Peacekeeper

The Peacekeeper architecture follows a "scale-to-zero" principle, optimized for Google Cloud Platform (GCP). It is designed to minimize latency during high-stress user interactions.

## Visual Architecture

### High-Level Component Diagram
```mermaid
graph TB
    UserA((User A))
    UserB((User B))

    subgraph Client_Layer [Frontend: Flutter]
        App[Peacekeeper Mobile/Web]
    end

    subgraph Logic_Layer [Backend: FastAPI on Cloud Run]
        API[API Gateway]
        Cache[(Response Cache)]
    end

    subgraph Intelligence_Layer [AI: Vertex AI]
        Gemini[[Gemini 2.5 Flash Lite]]
    end

    subgraph Data_Layer [State: Firebase]
        Auth[Anonymous Auth]
        DB[(Firestore Real-time DB)]
    end

    subgraph External_Services
        RC[RevenueCat]
        AdMob[Google AdMob]
    end

    UserA <--> App
    UserB <--> App
    App <-->|gRPC Snapshots| DB
    App <-->|REST/HTTPS| API
    App -->|Verify| Auth
    API -->|Prompting| Gemini
    API <-->|Lookup| Cache
    App -->|Subscription| RC
    App -->|Ads| AdMob
```

### 5-Phase Session Flow (Real-time Sync)
```mermaid
sequenceDiagram
    participant A as User A (Initiator)
    participant FS as Firestore (State Machine)
    participant API as Backend (AI Engine)
    participant B as User B (Joiner)

    Note over A, B: Phase 1: Regulation (Breathing)
    A->>FS: Create Session (Status: Waiting)
    B->>FS: Join Session (Status: Active)
    A->>A: 60s Breathing
    B->>B: 60s Breathing
    A->>FS: Ready
    B->>FS: Ready
    
    Note over A, B: Phase 2: Guided Expression
    FS->>A: Start Turn (Speaker)
    FS->>B: Start Turn (Listener)
    A->>API: Validate Observation (Regex/AI)
    API-->>A: Neutral Alternatives
    A->>FS: Send Message (Step 1-4)

    Note over A, B: Phase 3: Empathetic Reflection
    FS->>B: New Message Received
    B->>API: Generate Reflection
    API-->>B: Coaching Statement
    B->>B: Read Aloud & Confirm

    Note over A, B: Phase 4: Role Reversal / Closing
    Note right of FS: Optional: Swap Turns
    A->>FS: Rate Session
    B->>FS: Rate Session
    FS-->>A: Show Summary & Ads
    FS-->>B: Show Summary & Ads
```

## Architectural Layers

### 1. Orchestration Layer (Firebase)
- **Firestore:** Acts as the real-time state machine for shared sessions. Manages synchronization between devices without persistent WebSocket connections.
- **Anonymous Auth:** Provides session-based identity, ensuring privacy while maintaining a consistent user context for premium features.

### 2. Logic Layer (FastAPI + Vertex AI)
- **Cloud Run:** Hosts the Python backend. Handles NVC-lite logic, message filtering, and vocabulary serving.
- **Gemini 2.5 Flash Lite:** Used for:
  - Neutralizing observations (Phase 1)
  - Suggesting core feelings (Phase 2)
  - Identifying universal needs (Phase 3)
  - Refining actionable requests (Phase 4)
  - Generating empathetic reflections (Phase 5)

### 3. Monetization & Feedback Layer
- **RevenueCat:** Unified SDK for managing iOS/Android subscriptions and entitlements. Supports "SOS Day Pass" and "Monthly Premium".
- **Google AdMob:** Native banner ads integrated into the session closing screen for free users.
- **Promo Code System:** Custom Firestore-backed gift card system for manual premium overrides.

### 4. Safety Layer
- **Offensive Gate:** AI-driven validation in Phases 1 and 4. Blocks progress if judgmental or demanding language is detected.
- **CBT Stopping Questions:** Contextual interventions ("Am I certain about this interpretation?") that appear when the AI flags impulsive language.

## Data Flow (High Level)
1. User enters text.
2. Frontend debounces and sends to Backend.
3. Backend checks cache; if miss, calls Gemini via Vertex AI.
4. AI Response is parsed into clean neutral alternatives.
5. User selects an alternative, updating the shared session state in Firestore.