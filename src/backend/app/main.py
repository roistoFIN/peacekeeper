import os
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, firestore
from better_profanity import profanity

# Initialize Firebase Admin
if not firebase_admin._apps:
    firebase_admin.initialize_app()

app = FastAPI(title="Peacekeeper API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins (for development)
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods (GET, POST, OPTIONS, etc.)
    allow_headers=["*"],  # Allows all headers
)

# Initialize profanity filter
profanity.load_censor_words()
# Add custom blame patterns to block
custom_bad_words = ['you must', 'you always', 'you never', 'always', 'never']
profanity.add_censor_words(custom_bad_words)

class TextCheckRequest(BaseModel):
    text: str

class TextCheckResponse(BaseModel):
    is_safe: bool
    censored_text: str
    flagged: bool

@app.get("/")
def read_root():
    """Health check endpoint."""
    return {"status": "online", "service": "Peacekeeper API v0.1"}

@app.get("/health")
def health_check():
    """Detailed health check for Cloud Run probes."""
    return {"status": "healthy"}

@app.post("/analyze/safety", response_model=TextCheckResponse)
def check_safety(request: TextCheckRequest):
    """
    Checks the input text for profanity.
    Returns whether it's safe and a censored version.
    """
    text = request.text
    
    if not text:
        return TextCheckResponse(is_safe=True, censored_text="", flagged=False)

    contains_profanity = profanity.contains_profanity(text)
    censored = profanity.censor(text)
    
    return TextCheckResponse(
        is_safe=not contains_profanity,
        censored_text=censored,
        flagged=contains_profanity
    )