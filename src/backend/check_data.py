import firebase_admin
from firebase_admin import credentials, firestore
import os

# Initialize Firebase
PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT", "peacekeeper-483320")

if not firebase_admin._apps:
    firebase_admin.initialize_app(options={'projectId': PROJECT_ID})

db = firestore.client()

def check_validation_rules():
    print(f"Checking Firestore (Project: {PROJECT_ID}) for 'validation_rules'...")
    
    doc_ref = db.collection('config_metadata').document('validation_rules')
    doc = doc_ref.get()
    
    if doc.exists:
        data = doc.to_dict()
        print("\n--- Validation Rules Found ---")
        
        # Check Violent Words
        violent_words = data.get('violent_words', [])
        print(f"Violent Words Count: {len(violent_words)}")
        if "cunt" in violent_words:
            print("✅ 'cunt' IS present in violent_words.")
        else:
            print("❌ 'cunt' is MISSING from violent_words.")
            
        # Check Blame Patterns
        blame_patterns = data.get('blame_patterns', [])
        print(f"Blame Patterns Count: {len(blame_patterns)}")
        
        # Print a sample
        print("\nSample Violent Words:", violent_words[:5])
    else:
        print("❌ 'config_metadata/validation_rules' document DOES NOT EXIST.")

if __name__ == "__main__":
    check_validation_rules()
