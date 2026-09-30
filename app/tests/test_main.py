import pytest
from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


@pytest.mark.parametrize("path", ["/health", "/health/live", "/health/ready"])
def test_health_endpoints(path):
    response = client.get(path)

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
