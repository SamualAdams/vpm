# PR 4a: MCP tools and browser chat routes

## Summary
Define the MCP tool surface for VS Code integration, add FastAPI WebSocket and SSE endpoints for browser-based chat and real-time updates, and enforce confirm-before-write at the server layer.

## Why
VS Code and other agent clients need a stable MCP interface. The browser UI needs WebSocket for chat and SSE for real-time updates. Both access modes must enforce the same rule: nothing writes to Azure DevOps without explicit user approval through the action staging flow.

## Scope

### MCP tools (`vpm/mcp_server.py`)
Expose via Python MCP SDK (stdio transport):

| Tool | Description |
|---|---|
| `get_config` | Return current profile (masked secrets) |
| `query_board` | Query work items via WIQL or text search |
| `query_board_enriched` | Query work items with derived statuses (stale, blocked, drifting) |
| `stage_transcript` | Submit meeting notes or transcript text; creates a thread |
| `list_actions` | List recommended actions by status (open, approved, etc.) |
| `review_action` | Get full detail of a specific action including evidence and "what changes" preview |
| `apply_action` | Execute an approved action against Azure DevOps |
| `query_repos` | List commits or PRs with optional filters |
| `invoke_play` | Trigger a named play; returns the run ID |

### Browser chat endpoint
- `WebSocket /ws/chat` — accepts user messages, routes to the same orchestration layer used by MCP tools, streams responses back
  - Message format: `{ "type": "message", "content": "...", "thread_id": "..." }`
  - Response format: `{ "type": "response", "content": "...", "thread_id": "..." }` (streamed in chunks)
  - Creates/continues a thread for each conversation

### Real-time event stream
- `GET /api/events` (SSE) — server-sent events for:
  - `insight_created` — new insight generated
  - `action_created` — new action staged in inbox
  - `action_updated` — action status changed (approved, completed, etc.)
  - `board_changed` — work item state changed (after an action is applied)
- Event format: `{ "event": "insight_created", "data": { ... } }`

### Confirm-before-write enforcement
- `apply_action` (both MCP and HTTP) checks that the action is in `approved_pristine` or `approved_modified` status before executing
- Execution calls the Azure DevOps client write methods from PR 2b
- On success: transitions action to `completed`
- On failure: transitions action to `failed` with error details in the event

### FastAPI routes (HTTP equivalents for browser)
- `POST /api/actions/{id}/approve` — approve pristine
- `POST /api/actions/{id}/approve-modified` — approve with edits (accepts modified payload)
- `POST /api/actions/{id}/dismiss` — dismiss
- `POST /api/actions/{id}/apply` — execute approved action
- `POST /api/chat` — non-WebSocket fallback for sending a message (returns full response, no streaming)
- `POST /api/transcript` — submit transcript text

### VS Code integration
- `.mcp.json.example` documenting how to register the MCP server with VS Code / Claude Code

## Acceptance Criteria
- MCP client can discover and call all listed tools
- `stage_transcript` via MCP creates a thread (orchestration deferred to PR 4b, but the tool and thread creation work)
- `apply_action` rejects actions not in an approved state
- `apply_action` executes approved actions against Azure DevOps and transitions to `completed` or `failed`
- WebSocket `/ws/chat` accepts a message and returns a response (placeholder response OK — real orchestration in PR 4b)
- SSE `/api/events` streams events when actions are created or updated
- All approval/dismiss/apply routes work and create proper audit events
- `.mcp.json.example` is present and documents VS Code setup
- All endpoints have tests

## Out of Scope
- LangChain chain execution (PR 4b) — this PR wires the tools and routes; PR 4b adds the intelligence
- Full UI (PR 5)
- Scheduled play execution
- Advanced streaming (token-by-token LLM output)

## Risks / Notes
- The MCP server runs as a separate stdio process. For tools that need to create/read domain records (threads, actions), both the MCP server and FastAPI server access the same SQLite database via WAL mode. This works for single-user local usage but would need rearchitecting for multi-user.
- WebSocket chat initially returns placeholder responses. PR 4b plugs in real LangChain orchestration.
- SSE connection should handle reconnection gracefully (send `Last-Event-ID` support).
