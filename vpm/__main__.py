from vpm.app import app
from vpm.config import get_settings
from vpm.db import init_db


def main() -> None:
    import uvicorn

    settings = get_settings()
    init_db()
    uvicorn.run(app, host=settings.host, port=settings.port)


if __name__ == "__main__":
    main()
