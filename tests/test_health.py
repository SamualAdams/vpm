from httpx import ASGITransport, AsyncClient

from vpm.app import create_app


async def test_health_reports_ok_and_wal_mode() -> None:
    app = create_app()

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://testserver",
    ) as client:
        response = await client.get("/health")

    assert response.status_code == 200

    payload = response.json()
    assert payload["status"] == "ok"
    assert payload["wal_mode"].lower() == "wal"
    assert payload["database_path"].endswith("vpm.db")
