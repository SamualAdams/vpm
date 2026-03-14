# PR 2b: Azure DevOps HTTP client

## Summary
Implement the typed Azure DevOps HTTP client for Boards and Repos access, with pagination, error normalization, and FastAPI routes to expose queries.

## Why
Every downstream feature — board views, enrichment, agent reasoning, action application — depends on reliable Azure DevOps data access. This PR isolates the integration complexity so later PRs can treat it as a stable service layer.

## Scope
- Typed Azure DevOps HTTP client (`vpm/azure/client.py`):
  - Uses `httpx.AsyncClient` with PAT-based auth from stored config
  - Boards:
    - `get_work_item(id)` — single work item with all fields
    - `list_work_items(query)` — WIQL query execution with result hydration
    - `search_work_items(text, filters)` — text search with field filters
    - `create_work_item(type, fields)` — create with field patch
    - `update_work_item(id, fields)` — update with field patch
  - Repos:
    - `list_commits(repo, branch, date_range)` — commit listing with pagination
    - `list_pull_requests(repo, status)` — PR listing with pagination
    - `get_pull_request(repo, pr_id)` — single PR with details
  - Pagination: automatic continuation token handling
  - Rate limiting: respect `Retry-After` headers, exponential backoff
  - Error normalization: all Azure errors mapped to structured error schema from PR 2a
- Pydantic models for Azure DevOps entities (WorkItem, Commit, PullRequest)
- FastAPI routes:
  - `GET /api/board/items` — list/query work items
  - `GET /api/board/items/{id}` — get single work item
  - `GET /api/repos/commits` — list commits
  - `GET /api/repos/pull-requests` — list PRs
- Tests with mocked HTTP responses for all client methods

## Acceptance Criteria
- Board queries return real data for the configured org and project (manual verification)
- WIQL queries execute and return hydrated work items
- Work item create and update work at the service layer
- Commit and PR listing works with pagination
- Azure API errors (401, 404, 429, 5xx) are normalized into the structured error schema with actionable messages
- Rate limiting is handled transparently
- All client methods have tests with mocked responses

## Out of Scope
- Board enrichment / derived statuses (PR 3b)
- Direct write execution from API routes (writes go through action staging in PR 4a)
- Agent reasoning about board state
- UI rendering of board data

## Risks / Notes
- Azure DevOps REST API is inconsistent across endpoints — field names, pagination, and error formats vary. The client must normalize these differences.
- Write methods (`create_work_item`, `update_work_item`) exist at the service layer but are NOT exposed as direct API routes — they will only be called through the action application flow in PR 4a
- WIQL has a result limit of 200 work items per query — the client should document this limitation
