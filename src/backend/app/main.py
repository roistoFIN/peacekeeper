import os
from fastapi import FastAPI
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase Admin
# In Cloud Run, initialize_app() works automatically with the default service account.
# We check if it's already initialized to prevent errors during hot-reloads or tests.
if not firebase_admin._apps:
    firebase_admin.initialize_app()

app = FastAPI(title="Peacekeeper API")

@app.get("/")
def read_root():
    """Health check endpoint."""
    return {"status": "online", "service": "Peacekeeper API v0.1"}

@app.get("/health")
def health_check():
    """Detailed health check for Cloud Run probes."""
    return {"status": "healthy"}
