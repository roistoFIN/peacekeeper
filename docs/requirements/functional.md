# Functional Requirements: Peacekeeper

## Version 0.1+ Core User Flows

### 1. Start Screen
- **Action A: SOS - Conflict happening now** (Starts shared session).
- **Action B: Join an ongoing conversation** (Joins session via 6-digit code).
- **Action C: Guide me to express...** (Starts solo session).
- **Premium Status:** Displays "Premium enabled" (Green) or "Get Premium" button.

### 2. Session Phase 1: Regulation
- **Timer:** 60-second breathing countdown.
- **Goal:** Physiological de-escalation via Polyvagal theory.
- **Transition:** Proceeds only when the timer reaches zero and (in shared mode) both participants confirm readiness.

### 3. Session Phase 2: Expression (4-Step Wizard)
- **Step 1 (Observation):** "When [Action]..."
- **Step 2 (Feeling):** "I feel [Emotion]..."
- **Step 3 (Need):** "...because I need [Need]."
- **Step 4 (Request):** "Would you be willing to [Action]?"
- **Contextual Help:** Every step includes an (i) icon explaining "Impulsive vs. NVC" phrasing.

### 4. Session Phase 3: Reflection (Listener Side)
- **Coaching:** AI generates a role-reversed reflection statement.
- **Solo Mode:** Skips this phase, moving directly to summary.

### 5. Session Phase 4: Closing
- **Summary:** Displays all emotions identified during the session.
- **Rating:** 5-star session helpfulness check.
- **Feedback:** 1-star ratings automatically prompt a "What went wrong?" feedback form.
- **Ads:** Free users see a Google Ad banner above the final exit button.

## Monetization Rules

| Feature | Free Tier | Premium Tier |
| :--- | :--- | :--- |
| AI Guidance | Fixed template responses | Personalized Gemini suggestions |
| Language Validation | No AI validation | Real-time judgment detection |
| Ad Experience | Ad-supported (Closing) | Ad-free |
| SOS Capacity | Limited | Unlimited |
