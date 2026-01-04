## Cloud-Native Tech Stack

The application architecture focuses on services that scale to zero. The tech stack prioritizes real-time synchronization for the shared conflict session.

Frontend: Flutter. Cross-platform (iOS/Android) development from a single codebase. Integrates seamlessly with GCP and Firebase services.

Backend Logic: Google Cloud Run. Api is deployed as a container. It scales to zero when not in use.

Real-time Database: Firestore (Native Mode). Essential for the "two phones, one conflict" flow. Firestore allows real-time listeners so User B's screen can update instantly when User A completes a step.

Authentication: Firebase Anonymous Auth. Since Version 0.1 requires no account, this allows a creation of a temporary session-based identity to secure the 6-digit conflict code.

Static Assets: Google Cloud Storage. For hosting any audio/video files used in the "Shared Regulation Phase".