from functools import lru_cache
import sqlite3
from typing import Any

from vpm.config import get_settings


class Database:
    def __init__(self, database_path: str):
        self.database_path = database_path

    def connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(
            self.database_path,
            check_same_thread=False,
        )
        connection.row_factory = sqlite3.Row
        connection.execute("PRAGMA journal_mode=WAL;")
        connection.execute("PRAGMA foreign_keys=ON;")
        connection.execute("PRAGMA busy_timeout=5000;")
        return connection


@lru_cache
def get_database() -> Database:
    settings = get_settings()
    settings.ensure_state_dir()
    return Database(str(settings.database_path))


def init_db() -> None:
    with get_database().connect() as connection:
        connection.execute("SELECT 1")


def read_journal_mode() -> str:
    with get_database().connect() as connection:
        row = connection.execute("PRAGMA journal_mode;").fetchone()
    return str(row[0]) if row else "unknown"


def fetch_database_details() -> dict[str, Any]:
    settings = get_settings()
    return {
        "database_path": str(settings.database_path),
        "wal_mode": read_journal_mode(),
    }
