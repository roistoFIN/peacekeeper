import firebase_admin
from firebase_admin import credentials, firestore
import os

# Initialize Firebase (relies on GOOGLE_APPLICATION_CREDENTIALS or local login)
PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT", "peacekeeper-483320")

if not firebase_admin._apps:
    firebase_admin.initialize_app(options={'projectId': PROJECT_ID})

db = firestore.client()

def seed_database():
    print("Seeding NVC Database...")

    # 1. NVC VOCABULARY (Feelings & Needs)
    # Feelings
    feelings_data = {
        "categories": [
            {
                "name": "Sadness",
                "icon": "cloud_outlined",
                "words": ["disappointed", "despairing", "lonely", "hurt", "discouraged"]
            },
            {
                "name": "Fear",
                "icon": "bolt_outlined",
                "words": ["scared", "anxious", "insecure", "overwhelmed", "terrified"]
            },
            {
                "name": "Anger",
                "icon": "fire_extinguisher_outlined", # Using available material icons
                "words": ["frustrated", "resentful", "irritated", "furious", "annoyed"]
            },
            {
                "name": "Confusion",
                "icon": "question_mark_outlined",
                "words": ["baffled", "perplexed", "hesitant", "torn", "lost"]
            }
        ]
    }
    db.collection('nvc_vocabulary').document('feelings').set(feelings_data)
    print(" - Feelings seeded.")

    # Needs
    needs_data = {
        "categories": [
            {
                "name": "Connection",
                "icon": "favorite_border",
                "words": ["acceptance", "affection", "appreciation", "belonging", "empathy"]
            },
            {
                "name": "Autonomy",
                "icon": "flight_takeoff",
                "words": ["choice", "freedom", "independence", "space", "spontaneity"]
            },
            {
                "name": "Peace",
                "icon": "spa_outlined",
                "words": ["beauty", "ease", "equality", "harmony", "order"]
            },
            {
                "name": "Meaning",
                "icon": "lightbulb_outline",
                "words": ["clarity", "competence", "growth", "hope", "purpose"]
            }
        ]
    }
    db.collection('nvc_vocabulary').document('needs').set(needs_data)
    print(" - Needs seeded.")

    # 2. VALIDATION RULES (Blame & Pseudo-feelings)
    validation_rules = {
        "blame_patterns": [
            r"(?i)\byou\s+(always|never)",  # "You always", "You never"
            r"(?i)\byou\s+made\s+me",      # "You made me"
            r"(?i)\byou\s+should",         # "You should"
            r"(?i)\byou\s+must",           # "You must"
            r"(?i)\byou\s+are\s+(so|too|just)", # "You are so..."
        ],
        "pseudo_feelings": [
            "ignored", "betrayed", "abandoned", "manipulated", "rejected", 
            "unappreciated", "unheard", "unwanted", "used", "attacked", 
            "blamed", "cheated", "cornered", "criticized", "distrusted"
        ]
    }
    db.collection('config_metadata').document('validation_rules').set(validation_rules)
    print(" - Validation Rules seeded.")

    # 3. TEMPLATES
    templates = {
        "default_nvc": {
            "structure": "When {observation}, I feel {feeling} because I need {need}. Would you be willing to {request}?",
            "fields": ["observation", "feeling", "need", "request"]
        }
    }
    db.collection('config_metadata').document('templates').set(templates)
    print(" - Templates seeded.")

    print("Database seeding complete!")

if __name__ == "__main__":
    seed_database()
