import pytest
from fastapi.testclient import TestClient

from app import APP_NAME, __version__
from app.main import app


@pytest.fixture
def client() -> TestClient:
    """Fixture providing a FastAPI TestClient instance."""
    return TestClient(app)


def test_root_endpoint(client: TestClient) -> None:
    """Test that GET / returns status 200, application name, version, and message."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == APP_NAME
    assert data["version"] == __version__
    assert "message" in data
    assert isinstance(data["message"], str)
    assert len(data["message"]) > 0


def test_health_endpoint(client: TestClient) -> None:
    """Test that GET /health returns status 200 and healthy status."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data == {"status": "healthy"}


def test_version_endpoint(client: TestClient) -> None:
    """Test that GET /version returns status 200 and current version."""
    response = client.get("/version")
    assert response.status_code == 200
    data = response.json()
    assert data == {"version": __version__}
