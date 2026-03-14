# VPM

Virtual Project Manager is a local-first app for working with Azure DevOps Boards and Repos through a curated agent and MCP surface.

This bootstrap slice gives you:

- a FastAPI backend with a health endpoint
- a local SQLite database configured for WAL mode
- a stdio MCP server entrypoint
- a React + Vite frontend shell for the workspace
- backend and frontend test scaffolding

## Prerequisites

- Python 3.13+
- `uv`
- Node.js 20+
- npm 11+

## Backend

Install dependencies and start the API:

```bash
uv sync --group dev
uv run vpm
```

The backend runs on `http://127.0.0.1:8000` by default.

## One-command demo loop

Start everything, run the automated checks, and boot the backend and frontend:

```bash
./start.sh
```

Stop the local servers:

```bash
./stop.sh
```

`start.sh` does the following each time:

- runs `uv sync --group dev`
- runs `npm ci` in `web/`
- runs `uv run pytest`
- runs `npm run test`
- runs `npm run build`
- starts the backend and frontend in the background
- writes logs and pid files under `.vpm/run/`

Health check:

```bash
curl http://127.0.0.1:8000/health
```

## MCP server

Run the local stdio MCP server:

```bash
uv run vpm-mcp
```

The server exposes a small bootstrap tool so MCP clients can verify that the workspace is alive before richer Azure DevOps tools are added.

## Frontend

Install frontend dependencies and start the workspace shell:

```bash
cd web
npm install
npm run dev
```

The Vite dev server runs on `http://127.0.0.1:5173` and proxies `/api` and `/health` requests to the FastAPI backend.

## Tests

Backend:

```bash
uv run pytest
```

Frontend:

```bash
cd web
npm run test
```

## Local state

VPM stores local runtime state under `.vpm/` by default:

- `vpm.db`: SQLite database

The database is opened with WAL mode enabled to support multiple local processes over time.

## Project layout

```text
vpm/
├── vpm/              # Python package
├── tests/            # Backend tests
├── web/              # React + Vite frontend
└── docs/prs/         # PR scaffolding
```
