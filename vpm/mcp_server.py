from mcp.server.fastmcp import FastMCP

from vpm.config import get_settings
from vpm.db import fetch_database_details, init_db


def build_server() -> FastMCP:
    server = FastMCP("vpm")

    @server.tool()
    def workspace_status() -> dict[str, str]:
        """Return bootstrap status for the local VPM workspace."""

        init_db()
        settings = get_settings()
        details = fetch_database_details()
        return {
            "status": "ok",
            "project_root": str(settings.project_root),
            "database_path": details["database_path"],
            "wal_mode": details["wal_mode"],
        }

    return server


def main() -> None:
    build_server().run(transport="stdio")


if __name__ == "__main__":
    main()
