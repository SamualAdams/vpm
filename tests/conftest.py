from collections.abc import Iterator

import pytest

from vpm.config import get_settings
from vpm.db import get_database


@pytest.fixture(autouse=True)
def isolated_state_dir(tmp_path, monkeypatch) -> Iterator[None]:
    monkeypatch.setenv("VPM_STATE_DIR", str(tmp_path / ".vpm"))
    get_settings.cache_clear()
    get_database.cache_clear()
    yield
    get_database.cache_clear()
    get_settings.cache_clear()
