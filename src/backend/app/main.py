import os
import re
from typing import List, Dict, Any, Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, firestore
from better_profanity import profanity

# Initialize Firebase Admin
if not firebase_admin._apps:
    firebase_admin.initialize_app()

db = firestore.client()
app = FastAPI(title="Peacekeeper API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize profanity filter
profanity.load_censor_words()

# --- Models ---
class ObservationRequest(BaseModel):
    text: str

class ValidationResponse(BaseModel):
    is_valid: bool
    suggestion: Optional[str] = None
    reason: Optional[str] = None
    censored_text: Optional[str] = None

class VocabularyResponse(BaseModel):
    feelings: Dict[str, Any]
    needs: Dict[str, Any]

# --- Helper: Fetch Rules ---
async def get_validation_rules():
    doc = db.collection('config_metadata').document('validation_rules').get()
    if doc.exists:
        return doc.to_dict()
    return {"blame_patterns": [], "pseudo_feelings": []}

# --- Endpoints ---

@app.get("/")
def read_root():
    return {"status": "online", "service": "Peacekeeper API v0.2"}

@app.get("/content/vocabulary", response_model=VocabularyResponse)
def get_vocabulary():
    """Fetches the NVC feelings and needs for the UI."""
    feelings_doc = db.collection('nvc_vocabulary').document('feelings').get()
    needs_doc = db.collection('nvc_vocabulary').document('needs').get()
    
    return VocabularyResponse(
        feelings=feelings_doc.to_dict() if feelings_doc.exists else {},
        needs=needs_doc.to_dict() if needs_doc.exists else {}
    )

@app.post("/validate/observation", response_model=ValidationResponse)
async def validate_observation(request: ObservationRequest):
    """
    Step 1 Check:
    1. Profanity check.
    2. Blame check (Regex from DB).
    """
    text = request.text
    
    # 1. Profanity
    if profanity.contains_profanity(text):
        return ValidationResponse(
            is_valid=False,
            reason="Language unsafe",
            suggestion="Please remove profanity.",
            censored_text=profanity.censor(text)
        )

    # 2. Blame Check
    rules = await get_validation_rules()
    patterns = rules.get('blame_patterns', [])
    
    for pattern in patterns:
        if re.search(pattern, text):
            return ValidationResponse(
                is_valid=False,
                reason="Blame detected",
                suggestion="It sounds like a judgment. Can you describe just the facts of what happened, starting with 'When I saw...'?"
            )

    return ValidationResponse(is_valid=True)

@app.post("/validate/feelings", response_model=ValidationResponse)
async def validate_feelings(request: ObservationRequest):
    """
    Step 2 Check:
    Checks for pseudo-feelings (e.g. 'betrayed', 'ignored').
    """
    text = request.text.lower()
    rules = await get_validation_rules()
    pseudos = rules.get('pseudo_feelings', [])
    
    for word in pseudos:
        if word in text:
            return ValidationResponse(
                is_valid=False,
                reason="Pseudo-feeling detected",
                suggestion=f"'{word.capitalize()}' is often a thought about what someone did to you, not a feeling. Try 'Hurt', 'Sad', or 'Scared'."
            )
            
    return ValidationResponse(is_valid=True)