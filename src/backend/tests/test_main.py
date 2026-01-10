from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import sys
import os

# Add the app directory to sys.path to allow importing main
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.main import app, parse_ai_alternatives

client = TestClient(app)

# --- Unit Tests ---

def test_parse_ai_alternatives_comma():
    text = "Alternatives: Try this, Or that, Maybe this"
    alts = parse_ai_alternatives(text)
    assert len(alts) == 3
    assert alts[0] == "Try this"

def test_parse_ai_alternatives_newline():
    text = "Alternatives:\n1. Option A\n2. Option B"
    alts = parse_ai_alternatives(text)
    assert len(alts) == 2
    assert alts[0] == "Option A"
    assert alts[1] == "Option B"

# --- Integration Tests (Mocked) ---

@patch("app.main.model.generate_content")
@patch("app.main.get_cached_response", return_value=None)
@patch("app.main.save_cached_response")
def test_neutralize_observation_offensive(mock_save, mock_get_cache, mock_generate):
    # Mock AI response
    mock_response = MagicMock()
    mock_response.text = "Judgment: Yes\nAlternatives: When I saw the dishes, When I noticed the mess"
    mock_generate.return_value = mock_response

    response = client.post(
        "/ai/neutralize-observation",
        json={"user_id": "test_user", "text": "You are lazy"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["is_offensive"] is True
    assert len(data["alternatives"]) == 2
    assert data["result"] == "When I saw the dishes"

@patch("app.main.model.generate_content")
@patch("app.main.get_cached_response", return_value=None)
@patch("app.main.save_cached_response")
def test_neutralize_observation_clean(mock_save, mock_get_cache, mock_generate):
    # Mock AI response
    mock_response = MagicMock()
    mock_response.text = "Judgment: No"
    mock_generate.return_value = mock_response

    response = client.post(
        "/ai/neutralize-observation",
        json={"user_id": "test_user", "text": "The dishes are in the sink"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["is_offensive"] is False
    assert data["result"] == "The dishes are in the sink"

@patch("app.main.get_cached_response", return_value=None)
@patch("app.main.save_cached_response")
def test_suggest_feelings_mock(mock_save, mock_get_cache):
    with patch("app.main.model.generate_content") as mock_generate:
        mock_response = MagicMock()
        mock_response.text = "angry, frustrated, tired"
        mock_generate.return_value = mock_response

        response = client.post(
            "/ai/suggest-feelings",
            json={"user_id": "test_user", "text": "I shouted"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "angry" in data["result"]
