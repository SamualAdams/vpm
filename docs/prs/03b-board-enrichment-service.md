# PR 3b: Board enrichment service

## Summary
Add the service layer that cross-references Azure DevOps work items with repo activity to derive operational statuses: stale, blocked, drifting, and untracked.

## Why
The narrative describes the Board as showing "what is actually in progress, blocked, stale, missing, or drifting from repo activity." Raw Azure DevOps board state doesn't tell you this — it requires comparing work item state against commit and PR activity. This enrichment is what makes the Board an operational surface rather than a mirror of Azure DevOps.

## Scope

### Enrichment logic (`vpm/services/enrichment.py`)
- **Stale**: work item is in an active state (`New`, `Active`, `In Progress`) but has no associated commits, PRs, or work item updates within the staleness window (configurable, default 7 days)
- **Blocked**: work item has a `Blocked` state, or has blocking dependency links in Azure DevOps
- **Drifting**: repo has commits or PRs that reference this work item (by ID in commit message or PR description), but the work item's board state doesn't reflect the activity. Examples:
  - PRs merged but item still in `In Progress` (should be `Done` or `Resolved`)
  - Commits pushed but item still in `New`
  - PR opened but item not in `In Progress`
- **Untracked**: commits or PRs in the repo that don't reference any work item by ID — potential missing board work

### Configuration
- Staleness threshold (days, default 7)
- Active states list (configurable per project, default: `New`, `Active`, `In Progress`)
- Terminal states list (default: `Done`, `Closed`, `Resolved`, `Removed`)
- Work item reference pattern in commit messages (default: `#\d+`, configurable regex)

### Matching logic
- Parse commit messages and PR titles/descriptions for work item ID references
- Build a map of work item ID → associated commits and PRs
- Compare each work item's current state against its repo activity to determine derived status

### FastAPI endpoint
- `GET /api/board/enriched` — returns work items annotated with derived statuses
  - Response includes the raw work item data plus:
    ```json
    {
      "enrichment": {
        "status": "drifting",
        "reason": "PR #42 merged 3 days ago but work item still in 'In Progress'",
        "last_repo_activity": "2026-03-11T14:30:00Z",
        "associated_commits": [...],
        "associated_prs": [...]
      }
    }
    ```
  - Supports filtering by derived status (e.g., `?status=stale`)
- `GET /api/board/untracked` — returns commits and PRs with no work item reference

### Tests
- Unit tests for each enrichment rule with fixture data
- Test configurable thresholds
- Test edge cases: work items with no repo activity, commits referencing nonexistent work items

## Acceptance Criteria
- Given a work item in `Active` state with no commits or PRs in 7 days → marked `stale`
- Given a work item with a merged PR but still in `In Progress` → marked `drifting` with explanation
- Given a work item in `Blocked` state → marked `blocked`
- Given commits that reference no work item → listed as `untracked`
- Thresholds are configurable via config
- `GET /api/board/enriched` returns annotated work items
- `GET /api/board/untracked` returns orphaned commits/PRs
- All enrichment logic has unit tests

## Out of Scope
- UI rendering of enriched board (PR 5)
- Automatic actions based on enrichment (could be a future play)
- Real-time polling / scheduled refresh
- ML-based matching beyond regex patterns

## Risks / Notes
- Work item reference parsing is regex-based and will miss references that don't follow the configured pattern. Document this limitation.
- Enrichment runs on-demand per request. For large boards, consider caching in a future PR.
- "Drifting" detection requires mapping PR merge state to expected board state — this mapping may vary by team process and should be configurable in a future iteration.
