import os
import re
import time
import hashlib
import logging
from typing import List, Dict, Any, Optional
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, firestore
from better_profanity import profanity
import vertexai
from vertexai.generative_models import GenerativeModel

# --- Configuration ---
# Global Debug Switch
DEBUG_MODE = os.getenv("GOOGLE_CLOUD_PROJECT", "peacekeeper-483320").lower() == "true"

# Setup Logging
logging.basicConfig(
    level=logging.DEBUG if DEBUG_MODE else logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S"
)
logger = logging.getLogger("peacekeeper")

PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT", "peacekeeper-483320")
REGION = "us-central1"

# Initialize Firebase
if not firebase_admin._apps:
    firebase_admin.initialize_app(options={'projectId': PROJECT_ID})

db = firestore.client()

# Initialize Vertex AI
try:
    vertexai.init(project=PROJECT_ID, location=REGION)
    logger.info(f"Vertex AI initialized for project {PROJECT_ID}")
except Exception as e:
    logger.error(f"Failed to initialize Vertex AI: {e}")

system_instruction = (
    "You are an expert NVC (Non-Violent Communication) coach and mediator. "
    "Your goal is to help users transform judgmental, hurtful, or blaming statements into "
    "neutral, fact-based observations. "
    "Judgmental statements often include interpretations of intent, evaluations, or blame. "
    "Neutral observations focus only on what a video camera would record. "
    "Never refuse a request to neutralize a statement. If an input is judgmental, "
    "provide exactly 1 to 3 neutral alternatives that capture the likely underlying factual observation. "
    "Stay strictly within the context provided by the user."
)

model = GenerativeModel(
    "gemini-2.5-flash-lite",
    system_instruction=[system_instruction]
)

app = FastAPI(title="Peacekeeper AI API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

profanity.load_censor_words()

def parse_ai_alternatives(text: str) -> List[str]:
    """Robustly parse AI alternatives from response text."""
    if "Alternatives:" not in text:
        return []
    
    alts_part = text.split("Alternatives:")[1].strip()
    # Remove potential brackets
    alts_part = alts_part.replace("[", "").replace("]", "")
    
    # Try splitting by newline first (often how Gemini formats lists)
    lines = [line.strip() for line in alts_part.split("\n") if line.strip()]
    
    # If it's one long line, try splitting by comma
    if len(lines) <= 1:
        lines = [s.strip() for s in alts_part.split(",") if s.strip()]
    
    # Clean up common list patterns (1. , - , etc.)
    cleaned = []
    for line in lines:
        # Remove leading numbers like "1. ", "2)", "- "
        line = re.sub(r'^(\d+[\.\)]|\-|\*)\s*', '', line).strip()
        if line:
            cleaned.append(line)
            
    return cleaned[:3]

# --- Caching Logic ---
async def get_cached_response(key_parts: List[str]):
    key = hashlib.sha256("".join(key_parts).encode()).hexdigest()
    doc = db.collection('cached_ai_responses').document(key).get()
    if doc.exists:
        data = doc.to_dict()
        # Expire after 10 minutes
        if time.time() - data.get('timestamp', 0) < 600:
            logger.debug(f"Cache HIT for key prefix: {key[:8]}")
            return data.get('response')
    logger.debug(f"Cache MISS for key prefix: {key[:8]}")
    return None

async def save_cached_response(key_parts: List[str], response: Any):
    key = hashlib.sha256("".join(key_parts).encode()).hexdigest()
    db.collection('cached_ai_responses').document(key).set({
        'response': response,
        'timestamp': time.time()
    })

# --- Models ---
class AIRequest(BaseModel):
    user_id: str
    text: Optional[str] = None
    context: Optional[Dict[str, Any]] = None

class AIResponse(BaseModel):
    result: Any
    alternatives: Optional[List[str]] = None
    is_offensive: bool = False
    from_cache: bool = False

# --- Endpoints ---

@app.post("/ai/neutralize-observation", response_model=AIResponse)
async def neutralize_observation(req: AIRequest):
    logger.info(f"Endpoint: neutralize-observation | User: {req.user_id} | Text: {req.text[:50]}...")
    
    cache_key = [req.user_id, "neutralize", req.text or ""]
    cached = await get_cached_response(cache_key)
    if cached:
        return AIResponse(result=cached, from_cache=True)

    # Use a structured prompt to get both validation and alternatives
    prompt = (
        "Analyze this observation: '{text}'.\n"
        "1. Is this statement judgmental, blaming, or offensive? (Yes/No)\n"
        "2. If Yes, provide 1 to 3 neutral, fact-based NVC alternatives. Do NOT use square brackets.\n"
        "3. If No, return the original text.\n"
        "Format your response as:\n"
        "Judgment: [Yes/No]\n"
        "Alternatives: alt1, alt2, ..."
    ).format(text=req.text)
    
    try:
        response = model.generate_content(prompt)
        resp_text = response.text.strip()
        logger.debug(f"Gemini Response: {resp_text}")
    except Exception as e:
        logger.error(f"Gemini Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
    # Parse the AI response
    is_offensive = "Judgment: Yes" in resp_text
    alts = parse_ai_alternatives(resp_text)

    # If the AI suggests changes, we consider it 'offensive' (judgmental) for the UI logic
    if is_offensive and alts:
        return AIResponse(result=alts[0], alternatives=alts, is_offensive=True)
    
    # Fallback to simple result if not flagged
    result = alts[0] if alts else req.text
    await save_cached_response(cache_key, result)
    return AIResponse(result=result)

@app.post("/ai/refine-request", response_model=AIResponse)
async def refine_request(req: AIRequest):
    logger.info(f"Endpoint: refine-request | User: {req.user_id}")
    context = req.context or {}
    cache_key = [req.user_id, "refine", req.text or "", str(context)]
    cached = await get_cached_response(cache_key)
    if cached:
        return AIResponse(result=cached, from_cache=True)

    # Use a structured prompt for requests
    prompt = (
        "Analyze this request: '{text}'. Context: Feelings={feelings}, Needs={needs}.\n"
        "1. Is this request a demand, offensive, or vague? (Yes/No)\n"
        "2. If Yes, provide exactly 1 to 3 positive, actionable NVC alternatives starting with 'Would you be willing to...'. Do NOT use square brackets.\n"
        "3. If No, return the original text.\n"
        "Format your response as:\n"
        "Judgment: [Yes/No]\n"
        "Alternatives: alt1, alt2, ..."
    ).format(text=req.text, feelings=context.get('feelings'), needs=context.get('needs'))
    
    try:
        response = model.generate_content(prompt)
        resp_text = response.text.strip()
        logger.debug(f"Gemini Response: {resp_text}")
    except Exception as e:
        logger.error(f"Gemini Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    
    # Parse the AI response
    is_offensive = "Judgment: Yes" in resp_text
    alts = parse_ai_alternatives(resp_text)

    if is_offensive and alts:
        return AIResponse(result=alts[0], alternatives=alts, is_offensive=True)
    
    result = alts[0] if alts else req.text
    await save_cached_response(cache_key, result)
    return AIResponse(result=result)

@app.post("/ai/suggest-feelings", response_model=AIResponse)
async def suggest_feelings(req: AIRequest):
    logger.info(f"Endpoint: suggest-feelings | User: {req.user_id}")
    # Check cache first
    cache_key = [req.user_id, "feelings", req.text or ""]
    cached = await get_cached_response(cache_key)
    if cached:
        return AIResponse(result=cached, from_cache=True)

    prompt = (
        f"Based on this conflict observation: '{req.text}', suggest 3 core emotions (from EFT/NVC) the speaker might feel. "
        "The speaker is the one sharing. The other person is the listener. "
        "Return ONLY a comma-separated list of 3 single words."
    )
    
    response = model.generate_content(prompt)
    result = [w.strip().lower() for w in response.text.split(",") if w.strip()]
    logger.debug(f"Generated Feelings: {result}")
    
    await save_cached_response(cache_key, result)
    return AIResponse(result=result)

@app.post("/ai/suggest-needs", response_model=AIResponse)
async def suggest_needs(req: AIRequest):
    logger.info(f"Endpoint: suggest-needs | User: {req.user_id}")
    feelings = req.context.get("feelings", "") if req.context else ""
    cache_key = [req.user_id, "needs", req.text or "", feelings]
    cached = await get_cached_response(cache_key)
    if cached:
        return AIResponse(result=cached, from_cache=True)

    prompt = (
        f"The speaker feels '{feelings}' about this observation: '{req.text}'. Suggest 3 universal human needs (NVC) "
        "that might be unmet for the speaker. Return ONLY a comma-separated list of 3 words."
    )
    
    response = model.generate_content(prompt)
    result = [w.strip().lower() for w in response.text.split(",") if w.strip()]
    logger.debug(f"Generated Needs: {result}")
    
    await save_cached_response(cache_key, result)
    return AIResponse(result=result)

@app.post("/ai/generate-reflection", response_model=AIResponse)
async def generate_reflection(req: AIRequest):
    logger.info(f"Endpoint: generate-reflection | User: {req.user_id}")
    ctx = req.context or {}
    cache_key = [req.user_id, "reflection", str(ctx)]
    cached = await get_cached_response(cache_key)
    if cached:
        return AIResponse(result=cached, from_cache=True)

    tone = "warm" if ctx.get("is_calm", True) else "objective and short"
    prompt = (
        "You are an NVC coach. Generate a reflection for the LISTENER to say to the SPEAKER. "
        "Context: The SPEAKER shared a message with the following parts: "
        "Observation: {observation}, Feelings: {feelings}, Needs: {needs}, Request: {request}. "
        "Crucial: In the provided Observation and Request context, 'I' refers to the SPEAKER and 'you' refers to the LISTENER. "
        "However, in the reflection you generate, 'I' refers to the LISTENER and 'You' refers to the SPEAKER. "
        "Do not invent facts."
        "The statement must: "
        "1. Acknowledge the speaker's feelings and needs. "
        "2. State the listener's willingness to consider changing their behavior to meet the speaker's need. "
        f"Tone: {tone}. Format: Just the reflection text."
    ).format(observation=ctx.get('observation'), feelings=ctx.get('feelings'), needs=ctx.get('needs'), request=ctx.get('request'))
    
    try:
        response = model.generate_content(prompt)
        result = response.text.strip()
        logger.debug(f"Generated Reflection: {result}")
        await save_cached_response(cache_key, result)
        return AIResponse(result=result)
    except Exception as e:
        logger.error(f"Reflection Generation Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/content/vocabulary")
def get_vocabulary():
    logger.info("Endpoint: get_vocabulary")
    feelings_doc = db.collection('nvc_vocabulary').document('feelings').get()
    needs_doc = db.collection('nvc_vocabulary').document('needs').get()
    return {
        "feelings": feelings_doc.to_dict() if feelings_doc.exists else {},
        "needs": needs_doc.to_dict() if needs_doc.exists else {}
    }