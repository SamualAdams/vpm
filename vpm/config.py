from dataclasses import dataclass
from functools import lru_cache
import os
from pathlib import Path


def _find_project_root() -> Path:
    current = Path.cwd().resolve()
    candidates = (current, *current.parents)

    for candidate in candidates:
        if (candidate / "pyproject.toml").exists():
            return candidate

    return current


def _parse_origins(raw_value: str | None) -> tuple[str, ...]:
    if raw_value:
        return tuple(origin.strip() for origin in raw_value.split(",") if origin.strip())
    return ("http://127.0.0.1:5173", "http://localhost:5173")


@dataclass(frozen=True)
class Settings:
    project_root: Path
    state_dir: Path
    database_path: Path
    host: str
    port: int
    cors_origins: tuple[str, ...]

    def ensure_state_dir(self) -> None:
        self.state_dir.mkdir(parents=True, exist_ok=True)


@lru_cache
def get_settings() -> Settings:
    project_root = Path(os.getenv("VPM_PROJECT_ROOT", _find_project_root())).resolve()
    state_dir = Path(os.getenv("VPM_STATE_DIR", project_root / ".vpm")).resolve()

    settings = Settings(
        project_root=project_root,
        state_dir=state_dir,
        database_path=state_dir / "vpm.db",
        host=os.getenv("VPM_HOST", "127.0.0.1"),
        port=int(os.getenv("VPM_PORT", "8000")),
        cors_origins=_parse_origins(os.getenv("VPM_CORS_ORIGINS")),
    )
    settings.ensure_state_dir()
    return settings
