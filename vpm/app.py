from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from vpm.config import get_settings
from vpm.db import init_db
from vpm.routes.health import router as health_router


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


def create_app() -> FastAPI:
    settings = get_settings()

    application = FastAPI(
        title="VPM",
        version="0.1.0",
        lifespan=lifespan,
    )
    application.add_middleware(
        CORSMiddleware,
        allow_origins=list(settings.cors_origins),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    application.include_router(health_router)

    @application.get("/")
    async def root() -> dict[str, str]:
        return {
            "name": "VPM",
            "message": "Bootstrap backend is running.",
        }

    return application


app = create_app()
