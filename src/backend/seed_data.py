import firebase_admin
from firebase_admin import credentials, firestore
import os

# Initialize Firebase (relies on GOOGLE_APPLICATION_CREDENTIALS or local login)
PROJECT_ID = os.getenv("GOOGLE_CLOUD_PROJECT", "peacekeeper-483320")

if not firebase_admin._apps:
    firebase_admin.initialize_app(options={'projectId': PROJECT_ID})

db = firestore.client()

def seed_database():
    print("Seeding NVC Database with Expanded Vocabulary...")

    # 1. NVC VOCABULARY (Feelings & Needs)
    # Feelings (Source: Hoffman Institute)
    feelings_data = {
        "categories": [
            {
                "name": "Happy",
                "icon": "sentiment_satisfied_alt",
                "words": [
                    "Amused", "Delighted", "Glad", "Joyful", "Pleased", "Satisfied", "Content", "Charmed", "Grateful", "Optimistic",
                    "Ecstatic", "Thrilled", "Elated", "Jubilant", "Euphoric", "Enthusiastic", "Excited", "Overjoyed"
                ]
            },
            {
                "name": "Sad",
                "icon": "sentiment_dissatisfied",
                "words": [
                    "Depressed", "Despair", "Dejected", "Heavy", "Crushed", "Disgusted", "Disappointed", "Dismayed", "Dampened",
                    "Grief", "Weepy", "Miserable", "Melancholy", "Sorrowful", "Mournful", "Gloomy", "Hopeless", "Heartbroken"
                ]
            },
            {
                "name": "Angry",
                "icon": "whatshot",
                "words": [
                    "Annoyed", "Agitated", "Fed up", "Irritated", "Mad", "Critical", "Resentful", "Disgusted", "Outraged", "Raging",
                    "Furious", "Livid", "Bitter", "Indignant", "Irate", "Hostile", "Vengeful", "Wrathful"
                ]
            },
            {
                "name": "Afraid",
                "icon": "error_outline",
                "words": [
                    "Anxious", "Apprehensive", "Cautious", "Concerned", "Dread", "Fearful", "Foreboding", "Frightened", "Mistrustful",
                    "Panicked", "Petrified", "Scared", "Suspicious", "Terrified", "Wary", "Worried", "Insecure", "Nervous"
                ]
            },
            {
                "name": "Confused",
                "icon": "question_mark",
                "words": [
                    "Baffled", "Bewildered", "Dazed", "Disoriented", "Distracted", "Doubtful", "Flustered", "Hesitant", "Lost",
                    "Mystified", "Perplexed", "Puzzled", "Skeptical", "Torn", "Uncertain", "Undecided", "Unsure"
                ]
            },
            {
                "name": "Strong",
                "icon": "fitness_center",
                "words": [
                    "Empowered", "Capable", "Confident", "Determined", "Energetic", "Forceful", "Invincible", "Mighty", "Powerful",
                    "Resilient", "Robust", "Secure", "Steady", "Sure", "Tough", "Vigorous", "Bold", "Brave"
                ]
            },
            {
                "name": "Inspired",
                "icon": "lightbulb",
                "words": [
                    "Amazed", "Awed", "Wonder", "Eager", "Keen", "Inspired", "Moved", "Touched", "Stimulated", "Motivated",
                    "Creative", "Imaginative", "Insightful", "Visionary", "Awakened", "Enlightened"
                ]
            },
            {
                "name": "Relaxed",
                "icon": "spa",
                "words": [
                    "Calm", "Comfortable", "Composed", "Content", "Cool", "Easy", "Mellow", "Peaceful", "Quiet", "Restful",
                    "Serene", "Still", "Tranquil", "Unflappable", "Untroubled", "At ease", "Soothed", "Relieved"
                ]
            },
            {
                "name": "Loving",
                "icon": "favorite",
                "words": [
                    "Affectionate", "Caring", "Compassionate", "Fond", "Friendly", "Loving", "Open", "Sympathetic", "Tender",
                    "Warm", "Adoring", "Cherishing", "Devoted", "Doting", "Infatuated", "Passionate", "Yearning", "Sentimental"
                ]
            }
        ]
    }
    db.collection('nvc_vocabulary').document('feelings').set(feelings_data)
    print(" - Feelings seeded.")

    # Needs (Source: Andrew Benjamin George / CNVC)
    needs_data = {
        "categories": [
            {
                "name": "Connection",
                "icon": "group",
                "words": [
                    "Acceptance", "Affection", "Appreciation", "Belonging", "Cooperation", "Communication", "Closeness", "Community",
                    "Companionship", "Compassion", "Consideration", "Consistency", "Empathy", "Inclusion", "Intimacy", "Love",
                    "Mutuality", "Nurturing", "Respect", "Safety", "Security", "Stability", "Support", "To know and be known",
                    "To see and be seen", "To understand and be understood", "Trust", "Warmth"
                ]
            },
            {
                "name": "Physical Well-Being",
                "icon": "accessibility_new",
                "words": [
                    "Air", "Food", "Movement", "Exercise", "Rest", "Sleep", "Safety", "Shelter", "Touch", "Water", "Sexual Expression"
                ]
            },
            {
                "name": "Honesty",
                "icon": "verified",
                "words": [
                    "Authenticity", "Integrity", "Presence", "Transparency", "Truth", "Clarity", "Congruence"
                ]
            },
            {
                "name": "Play",
                "icon": "sports_esports",
                "words": [
                    "Joy", "Humor", "Fun", "Recreation", "Amusement", "Laughter", "Spontaneity", "Adventure"
                ]
            },
            {
                "name": "Peace",
                "icon": "landscape",
                "words": [
                    "Beauty", "Communion", "Ease", "Equality", "Harmony", "Inspiration", "Order", "Serenity", "Tranquility", "Balance"
                ]
            },
            {
                "name": "Autonomy",
                "icon": "flight",
                "words": [
                    "Choice", "Freedom", "Independence", "Space", "Spontaneity", "Empowerment", "Self-expression"
                ]
            },
            {
                "name": "Meaning",
                "icon": "stars",
                "words": [
                    "Awareness", "Celebration of life", "Challenge", "Clarity", "Competence", "Consciousness", "Contribution",
                    "Creativity", "Discovery", "Efficacy", "Effectiveness", "Growth", "Hope", "Learning", "Mourning", "Participation",
                    "Purpose", "Self-expression", "Stimulation", "To matter", "Understanding"
                ]
            }
        ]
    }
    db.collection('nvc_vocabulary').document('needs').set(needs_data)
    print(" - Needs seeded.")

    # 2. VALIDATION RULES (Blame & Pseudo-feelings & Violent Speech)
    validation_rules = {
        "blame_patterns": [
            r"(?i)\byou\s+(always|never)",  # "You always", "You never"
            r"(?i)\byou\s+made\s+me",      # "You made me"
            r"(?i)\byou\s+should",         # "You should"
            r"(?i)\byou\s+must",           # "You must"
            r"(?i)\byou\s+are\s+(so|too|just)", # "You are so..."
            r"(?i)\byour\s+fault",         # "Your fault"
            r"(?i)\bblame\s+you",          # "Blame you"
            r"(?i)\bif\s+you\s+loved\s+me", # "If you loved me"
            r"(?i)\bwhy\s+can\'?t\s+you",  # "Why can't you"
            r"(?i)\byou\s+don\'?t\s+care", # "You don't care"
        ],
        "violent_words": [
            # Insults
            "idiot", "stupid", "dumb", "crazy", "lazy", "useless", "worthless", "failure", "loser", "jerk", "asshole",
            "bitch", "bastard", "dick", "cunt", "shit", "fuck", "damn", "hell", "piss", "crap", "suck",
            "psycho", "insane", "narcissist", "toxic", "abusive", "trash", "garbage",
            
            # Threats/Violence
            "kill", "punch", "hit", "slap", "beat", "hurt", "smack", "kick", "choke", "murder", "dead", "die",
            "hate", "despise", "disgusting", "pathetic", "shut up"
        ],
        "pseudo_feelings": [
            "ignored", "betrayed", "abandoned", "manipulated", "rejected", 
            "unappreciated", "unheard", "unwanted", "used", "attacked", 
            "blamed", "cheated", "cornered", "criticized", "distrusted",
            "intimidated", "let down", "misunderstood", "neglected", "overworked",
            "patronized", "pressured", "provoked", "put down", "threatened", "unloved", "unseen"
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