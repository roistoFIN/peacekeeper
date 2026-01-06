## Requirements Specification

**An application that helps during an active conflict.
In-the-moment conflict coaching.**

The name of the application is Peacekeeper: Couples Coach.

## Functional Requirements – Version 0.1

### Core Question

> “How do I prevent this conflict from escalating *right now*?”

Excluded:

* Relationship analysis
* Background history
* Personality or profile psychology

---

## User Flow (5–7 minutes)

**Two participants, two phones, one conflict**

* Each participant uses their own device
* The conflict is a shared session, but each user has a separate view
* Turns are locked to prevent interruptions
* No account required
* Uses a one-time conflict code

---

### 0. Start Screen

Two primary actions:

* **“SOS – Conflict happening now”**
* **“Join an ongoing conversation”**

Short copy:

> “This app helps you speak and listen more safely.”

---

### 1. Conflict Session Creation

**User A (initiator)**

* Presses *“SOS – Conflict happening now”*
* The app generates a one-time **6-digit conflict code**
* Screen message:

> “Ask the other person to join this conversation.”

**User B (joiner)**

* Selects *“Join an ongoing conversation”*
* Enters the code

**Both users see:**

> “You are now in the same conversation.
> The app will guide turns.”

---

### 2. Shared Regulation Phase (Gottman + Polyvagal) – Synchronized

Both users see identical, locked content:

* Breathing / countdown animation
* 60-second timer

Text:

> “When the body calms down, conversation becomes possible.”

The next step is unavailable until the timer completes.

---

### 3. Transition to Guided Expression

After regulation, the app transitions directly to the guided workflow.

---

### 4. Guided Expression (One speaks, one listens)

The app randomly selects who speaks first.

**Speaker**
*   Sees the guided expression interface with a **120-second timer**.
*   The timer starts when the listener confirms readiness.
*   The session ends for both if the timer reaches zero.

**Listener**
*   Sees a button: *“I’m ready to listen”*.
*   After pressing it, sees: *"Waiting for expression..."* while the speaker is in the wizard.

---

## Guided Expression Workflow (AI-Enhanced)

The workflow is broken into four distinct phases to lower the "Limbic load" on the user. Each phase includes accumulated context from previous steps.

### Phase 1: Observation (The "When...")
**UI Logic:**
*   A single text field limited to **200 characters** with a sticky "When " prefix.

**AI Integration:**
*   Gemini analyzes the draft for judgmental language or interpretations.
*   **Offensive Gate:** If flagged as judgmental, the user is **blocked** from proceeding.
*   **Suggestions:** Gemini suggests 1-3 neutral alternatives. Tapping one replaces the text and allows progress.

---

### Phase 2: Feelings (The "I feel...")
**UI Logic:**
*   Shows Step 1 context.
*   Users select 1–2 chips from dynamic categories (Sadness, Fear, Anger, Confusion).

**AI Integration:**
*   Gemini suggests 3 "likely" feelings based on Phase 1. Users can toggle these or select others.

---

### Phase 3: Needs (The "Because I need...")
**UI Logic:**
*   Shows Step 1 & 2 context.
*   Users select 1–2 needs from categories (Connection, Autonomy, Peace, Meaning).

**AI Integration:**
*   Gemini suggests 3 needs based on selected feelings.

---

### Phase 4: Request (The "Would you be willing...?")
**UI Logic:**
*   Shows Step 1, 2, & 3 context.
*   A text field limited to **200 characters** with a sticky *"Would you be willing to "* prefix.

**AI Integration:**
*   **Offensive Gate:** Identical to Step 1. Blocks progress if the request is a demand or offensive.
*   **Refinement:** Suggests 1-3 positive, actionable alternatives.

---

### 5. Reflection Phase (Listener Side)

**The Repair Attempt:**
*   Gemini generates a cohesive **Reflection Statement** for the listener to read aloud.
*   **Perspective Shift:** AI correctly reverses roles (e.g., if speaker says "When you...", listener says "When I...").
*   **Commitment:** The statement includes an acknowledgement of feelings/needs and a willingness to consider behavioral change.
*   The listener must confirm they have shared the reflection to complete the turn.

---

### 6. Turn Switch

The same process repeats with roles reversed.

---

### 7. Shared Closing

Both users see:

> “You may not have solved everything.
> But you stayed connected.”

Neutral summary:

> “Emotions present in this conversation included:
> – disappointment
> – insecurity”

Options:

* “Thank you for trying”

---

### 8. Session End

* Conflict code expires
* No persistent history in version 0.1
* App returns to the start screen