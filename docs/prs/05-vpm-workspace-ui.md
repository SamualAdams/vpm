# PR 5: VPM workspace UI

## Summary
Build the browser workspace: first-launch setup, split-pane layout with collapsible left rail (Board, Inbox, Insights, Threads), and right pane for chat, transcript paste, evidence review, and action approval.

## Why
The UI is where non-IDE users interact with the system and where the team reviews recommendations and outcomes. The product should feel like a project operations console, not a generic chatbot.

## Scope

### First-launch setup
- Detect whether a profile exists (`GET /api/config`)
- If no profile: show setup screen with fields for Azure DevOps PAT, OpenAI API key, organization, project, and model
- Connection test button validates both integrations before saving
- After save, redirect to main workspace
- Future launches skip setup and go directly to workspace

### Layout
- Split-pane: collapsible left rail (≈280px) + right workspace
- Left rail has four sections, each expandable:
  - **Board** — kanban view
  - **Inbox** — pending actions
  - **Insights** — observations
  - **Threads** — conversation history
- Clicking an item in the left rail opens its detail in the right pane
- Right pane default state: chat input + transcript paste area

### Board view
- Kanban-style columns derived from Azure DevOps board states
- Each card shows: work item ID, title, assignee, type icon
- Enrichment badges: color-coded indicators for `stale` (amber), `blocked` (red), `drifting` (orange), `untracked` (gray)
- Hover or click a badge shows the enrichment reason (e.g., "PR #42 merged 3 days ago but item still in 'In Progress'")
- Data from `GET /api/board/enriched`
- Filter by derived status

### Inbox view
- List of recommended actions with status `open`
- Each action card shows:
  - Action type icon and label (e.g., "Create Story", "Link PR", "Move Item")
  - Source: which thread or play produced this action
  - Evidence summary: what observation supports this recommendation
  - **"What changes" preview**: before/after view of the affected work item's state
  - Three action buttons: **Approve**, **Edit & Approve**, **Dismiss**
- **Approve**: transitions to `approved_pristine`, then offers "Apply now?" to execute immediately
- **Edit & Approve**: opens an inline editor for the action payload (e.g., edit the story title, modify field changes). On save, transitions to `approved_modified` with diff captured.
- **Dismiss**: transitions to `dismissed`
- Sorted by recency (newest first)

### Insights view
- Cards showing:
  - Observation text
  - Confidence indicator (high/medium/low based on 0–1 score)
  - Timestamp
  - Source link (thread or play run)
  - Count of linked actions (with status breakdown)
- Click to open source thread in right pane
- Sorted by confidence (descending), then recency

### Threads view
- List of threads with title, source (conversation or play), timestamp
- Thread detail (right pane):
  - Full conversation with assistant responses
  - Citations rendered as clickable links to Azure DevOps entities
  - Linked insights shown as cards below the conversation
  - Linked actions shown with current status
- Click an insight or action to scroll to / highlight it

### Right pane — chat
- Chat input field with send button
- Transcript paste area (larger text input for pasting meeting notes)
- Submit triggers transcript analysis chain (via WebSocket or HTTP)
- Responses stream in via WebSocket
- New insights and actions appear in real-time in the left rail via SSE
- Thread context maintained across messages

### Real-time updates
- SSE connection to `/api/events`
- New insights: flash/highlight in Insights section
- New actions: flash/highlight in Inbox section with count badge
- Action status changes: update in-place
- Board changes: refresh affected cards

## Acceptance Criteria
- First launch shows setup screen; after config save, shows workspace
- Subsequent launches go directly to workspace
- Board view renders kanban columns with enrichment badges
- Inbox shows open actions with evidence and "what changes" preview
- User can approve pristine, edit-then-approve (with diff captured), or dismiss an action
- Approved action can be applied (triggers Azure DevOps write, transitions to completed/failed)
- Insights view shows cards sorted by confidence
- Thread detail shows conversation, citations, and linked insights/actions
- Chat input sends message and receives streamed response
- Transcript paste submits and creates a thread with insights
- SSE updates appear in real-time (new insights, new actions)
- Layout is responsive and the left rail collapses cleanly

## Out of Scope
- Rich kanban customization (drag-drop reordering, custom columns)
- Scheduler UI
- Multi-user support
- Advanced analytics dashboard (PR 6)
- Mobile layout
- Dark mode

## Risks / Notes
- The "what changes" preview for inbox items requires fetching the current work item state and computing the diff against the proposed action payload — this may require a dedicated preview endpoint or client-side computation
- Keep the board view usable but secondary to the insight/action workflow — it's context, not the primary interaction surface
- Threads are the narrative source of truth; Inbox and Insights are promoted outputs from threads
- Consider virtualized lists if boards or inboxes grow large (defer optimization to post-MVP)
