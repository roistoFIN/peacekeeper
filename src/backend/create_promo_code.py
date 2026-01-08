import firebase_admin
from firebase_admin import credentials, firestore
import os

# Initialize Firebase (relies on GOOGLE_APPLICATION_CREDENTIALS or local login)
PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT", "peacekeeper-483320")

if not firebase_admin._apps:
    firebase_admin.initialize_app(options={'projectId': PROJECT_ID})

db = firestore.client()

def create_code():
    code = "TEST-CODE"
    print(f"Creating/Resetting promo code: {code}")
    
    db.collection('promo_codes').document(code).set({
        'is_active': True,
        'duration_days': 30,
        'max_uses': 999,
        'used_count': 0,
        'created_at': firestore.SERVER_TIMESTAMP
    })
    
    print("Success! You can now use 'TEST-CODE' in the app to unlock Premium for 30 days.")

if __name__ == "__main__":
    create_code()
