# PR 2a: Config persistence and setup API

## Summary
Add SQLite schema for user profiles, Alembic migration infrastructure, and FastAPI endpoints for saving, loading, and validating configuration.

## Why
The app needs a single local profile with PAT, OpenAI key, default org, project, and model. This is the first thing a user interacts with, and every subsequent PR depends on stored config. Alembic is established here so all future schema changes use migrations.

## Scope
- Set up Alembic with SQLite backend and initial migration
- Create `profiles` table:
  - `id` (primary key)
  - `pat` (encrypted at rest using Fernet with a local key, or plaintext with explicit risk documentation)
  - `openai_api_key` (same encryption treatment as PAT)
  - `organization` (Azure DevOps org)
  - `project` (Azure DevOps project)
  - `model` (OpenAI model name, e.g. `gpt-4o`)
  - `created_at`, `updated_at`
- SQLModel models for Profile
- FastAPI routes:
  - `POST /api/config` — save new profile
  - `GET /api/config` — load current profile (returns masked secrets)
  - `PUT /api/config` — update profile
  - `POST /api/config/test-connection` — validate PAT against Azure DevOps API and OpenAI key against OpenAI API
- Shared structured error response schema (used by all subsequent PRs):
  ```json
  {
    "error": "connection_failed",
    "message": "Azure DevOps PAT validation failed: 401 Unauthorized",
    "details": {}
  }
  ```
- Tests for config CRUD and connection test (mocked external APIs)

## Acceptance Criteria
- `alembic upgrade head` applies the initial migration cleanly
- `POST /api/config` saves a profile; `GET /api/config` returns it with masked secrets
- `PUT /api/config` updates an existing profile
- `POST /api/config/test-connection` returns success/failure with actionable error messages for both Azure DevOps and OpenAI
- Secrets are not stored in plaintext (encrypted with Fernet) OR a `SECURITY.md` documents the accepted risk
- Error responses use the shared structured schema
- All new code has tests

## Out of Scope
- Azure DevOps data queries (PR 2b)
- Agent reasoning or chat
- UI for the setup flow (PR 5)
- Multi-profile support

## Risks / Notes
- Fernet encryption requires a local key stored in `.vpm/` — this is defense-in-depth, not a security boundary
- Connection test should timeout gracefully (5s) and return useful errors, not stack traces
- The structured error schema established here becomes the contract for all API errors
