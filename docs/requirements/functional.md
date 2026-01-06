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

### 3. Emotion – Private Phase (EFT)

Each user individually selects:

* 1–2 emotions:

---

### 4. Guided Expression (One speaks, one listens)

The app randomly selects who speaks first.

**Speaker**

* Initially sees: *“Waiting for the other person to be ready to listen.”*
* Then sees the guided expression interface with a **120-second timer**

**Listener**

* Sees a button: *“I’m ready to listen”*
* After pressing it:

> “Listen. Do not interrupt. You will get your turn.”

---

## Guided Expression UI (Speaker)

The interface is step-based and **not fully free-text**.

### Screen 1: Observation (no blame)

Title:

> “What happened – without blame?”

Emotion selected in Phase 3 constrains suggested wording.

Examples:

* “When yesterday ___”
* “When you said ___”
* “When something was not done ___”

Tip:

> “Describe what happened like a video camera – no opinions.”

---

### Screen 2: Emotion (pre-filled from Phase 3)

Select 1–2 emotions again for confirmation.
“You”-statements are blocked.

---

### Screen 3: Need (EFT + NVC)

Select:

* to be heard
* to receive support
* to feel safe
* to feel appreciated
* to gain clarity

Text:

> “I felt ___ because I need ___.”

---

### Screen 4: Request (not a demand)

Allowed formats:

* “Would you be willing to ___?”
* “Could you ___?”
* “Could we try ___?”

Blocked:

* “You must…”
* “Always / never”

---

### Screen 5: Final Combined Message (Preview)

Preview:

> “When ___ happened, I felt ___ because I need ___.
> Would you be willing to ___?”

Button:

> **“This feels fair – continue”**

---

### Safety Mechanisms (All Input Fields)

* Profanity blocked
* Blaming phrases trigger suggestions
* Overly long messages are truncated

---

### 5. Reflection (Listener)

After the speaker’s timer ends, the listener:

* Sees the speaker’s message
* Is prompted:

> “Select the sentence that best reflects what you heard.”

Only reflection options matching the speaker’s selected emotion are shown.

Examples:

* “I heard that you felt unsafe.”
* “I understood that this made you feel lonely.”
* “I may have misunderstood—please correct me.”

The speaker sees the selected reflection once sent.

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