from fastapi import APIRouter

from vpm.db import fetch_database_details, init_db

router = APIRouter(tags=["health"])


def _health_payload() -> dict[str, str]:
    init_db()
    details = fetch_database_details()
    return {
        "status": "ok",
        "database_path": details["database_path"],
        "wal_mode": details["wal_mode"],
    }


@router.get("/health")
async def health() -> dict[str, str]:
    return _health_payload()


@router.get("/api/health")
async def api_health() -> dict[str, str]:
    return _health_payload()
