To ensure the free tier lasts "forever," we implement a Layered Efficiency Model.

Layer 1: Client-Side "Pre-Filtering" (The First Gate)

Logic:

* Length Check: 200-character hard limit.

* Debouncing: 800ms wait after typing.

* Sequential Logic: AI suggestion box must be addressed before proceeding if text is judgmental.



Layer 2: Firestore Caching (The Second Gate)

Logic: 

* Every AI response is hashed and cached in `cached_ai_responses`.

* Expiry: 10 minutes. 

* Deduplication: Identical requests from the same user bypass Gemini entirely.



Layer 3: Backend Rate Limiting (The Final Gate)

Logic: 

* Token Bucket (5 tokens capacity, 1 refill/min).

* Return Code: 429 Too Many Requests.
