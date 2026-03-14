# PR 1: Bootstrap local VPM app skeleton

## Summary
Set up the full project skeleton: Python backend with FastAPI and MCP server, React + Vite frontend scaffold, SQLite with WAL mode, test infrastructure, and developer bootstrap docs.

## Why
We need a stable, runnable base before building integrations, agent workflows, or UI. This PR establishes the project structure, dependency tooling, and dev workflow so every subsequent PR has a consistent foundation.

## Stack established
- **Backend**: Python 3.12+, FastAPI, uv for dependency management
- **Frontend**: React + Vite + TypeScript in `web/`
- **Database**: SQLite with WAL mode (configured at connection time for multi-process safety)
- **MCP**: Python MCP SDK, stdio entrypoint
- **Testing**: pytest + pytest-asyncio + httpx (backend), Vitest + React Testing Library (frontend)

## Scope
- Initialize Python project with `pyproject.toml` and uv
- Create package structure:
  ```
  vpm/
  ├── __init__.py
  ├── __main__.py          # FastAPI app entrypoint
  ├── mcp_server.py        # MCP stdio server entrypoint
  ├── config.py            # Config loading from env / state dir
  ├── db.py                # SQLite connection with WAL mode
  └── routes/
      └── health.py        # GET /health placeholder
  ```
- Scaffold React + Vite frontend in `web/`:
  ```
  web/
  ├── package.json
  ├── tsconfig.json
  ├── vite.config.ts
  ├── index.html
  └── src/
      ├── main.tsx
      └── App.tsx           # App shell placeholder
  ```
- Define local state directory convention (`.vpm/` in project root, gitignored)
- Add `.env.example` with placeholder keys (PAT, OpenAI key, org, project, model)
- Add `.gitignore` covering `.vpm/`, `node_modules/`, `__pycache__/`, `.env`
- Add test scaffolds: `tests/test_health.py`, `web/src/App.test.tsx`
- Add `README.md` with dev workflow: how to run backend, frontend, MCP server, and tests
- Register `[project.scripts]` entrypoints: `vpm` (web app), `vpm-mcp` (MCP server)

## Acceptance Criteria
- `uv run vpm` starts the FastAPI server; `GET /health` returns 200
- `uv run vpm-mcp` starts the MCP stdio server and responds to `initialize`
- `cd web && npm install && npm run dev` starts the Vite dev server with the app shell
- SQLite database is created in `.vpm/` with WAL mode enabled
- `pytest` passes with at least one backend test
- `npm test` passes with at least one frontend test
- `.vpm/` directory is gitignored
- README documents the full dev setup workflow

## Out of Scope
- Real Azure DevOps API calls
- SQLite schema beyond connection setup
- Chat behavior or agent logic
- UI beyond a placeholder app shell
- Alembic migrations (introduced in PR 2a)

## Risks / Notes
- Keep secrets and local DB out of git — `.vpm/` and `.env` must be gitignored
- WAL mode must be set on every new SQLite connection (pragma, not a file property)
- The MCP server and FastAPI server are separate processes that share the same SQLite file — WAL mode is required from day one to avoid `SQLITE_BUSY` errors
- Frontend dev server proxies API calls to FastAPI backend during development
