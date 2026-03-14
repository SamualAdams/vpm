# VPM PR Drafts

This folder contains the staged PR scaffolding for building VPM in sequential slices.

## Stack

- **Backend**: Python, FastAPI, SQLite (WAL mode), SQLModel, Alembic
- **Frontend**: React + Vite + TypeScript
- **AI/Agent**: LangChain, OpenAI API
- **MCP**: Python MCP SDK (stdio)
- **Real-time**: SSE (server-push) + WebSocket (chat)
- **Tooling**: uv, pytest, Vitest

## Sequence

1. `01-bootstrap-local-vpm-app-skeleton.md`
2. `02a-config-persistence-and-setup-api.md`
3. `02b-azure-devops-http-client.md`
4. `03-domain-model-threads-plays-insights-actions.md`
5. `03b-board-enrichment-service.md`
6. `04a-mcp-tools-and-browser-chat-routes.md`
7. `04b-langchain-orchestration.md`
8. `05-vpm-workspace-ui.md`
9. `06-effectiveness-metrics-and-reporting.md`

## Usage

- Copy a draft into a GitHub PR description when opening the corresponding branch.
- Adjust scope and acceptance criteria if implementation discoveries require a split or merge.
- PRs are sequential — each depends on its predecessors.
