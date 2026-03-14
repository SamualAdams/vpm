# PR 6: Effectiveness metrics and reporting

## Summary
Add measurement and reporting so the team can evaluate whether VPM recommendations are useful and improving over time.

## Why
The product should show whether insights convert into actions and whether recommendations are accepted as-is or require edits. This turns the UI into both a control plane and a feedback loop. Without measurement, the system is just generating suggestions with no way to know if they're good.

## Scope

### Derived metrics
All metrics are computed from stored `action_events`, `recommended_actions`, `insights`, and `runs` records — never from transient chat text.

**Action outcome metrics** (by configurable time period):
- Count by terminal status: `approved_pristine`, `approved_modified`, `dismissed`, `completed`, `failed`
- Pristine approval rate: `approved_pristine / (approved_pristine + approved_modified + dismissed)`
- Completion rate: `completed / (approved_pristine + approved_modified)`
- Failure rate: `failed / (approved_pristine + approved_modified)`

**Conversion funnel**:
- Runs → insights (how many runs produce at least one insight)
- Insights → actions (how many insights produce at least one action)
- Actions → approved (approval rate)
- Approved → completed (execution success rate)

**Time metrics** (median and p90):
- Run start → first insight created
- Insight created → first action created
- Action created → approved
- Action approved → completed

**Play-level performance**:
- Per play: total runs, insight count, action count, approval rate, pristine rate
- Identifies which plays produce the most accepted recommendations

**Source-level comparison**:
- Conversation-originated vs play-originated: insight quality (measured by action conversion and approval rates)

### FastAPI endpoints
- `GET /api/metrics/actions` — action outcome counts and rates by period
- `GET /api/metrics/funnel` — conversion funnel metrics
- `GET /api/metrics/timing` — time-based metrics
- `GET /api/metrics/plays` — per-play performance summary
- `GET /api/metrics/sources` — conversation vs play comparison
- All endpoints accept `?from=DATE&to=DATE` for period filtering

### UI reporting view
- New section in the left rail or accessible from a dashboard icon
- Summary cards: total actions, approval rate, pristine rate, average time-to-action
- Funnel visualization: runs → insights → actions → approved → completed
- Play performance table: sortable by approval rate, pristine rate, total runs
- Time trend: action outcomes over the last 30 days (bar or line chart)

## Acceptance Criteria
- `GET /api/metrics/actions` returns correct counts from `action_events` data
- Pristine vs modified approval rates are distinguishable
- Funnel metrics accurately reflect the conversion chain
- Time metrics compute median and p90 correctly
- Play-level metrics attribute outcomes to the correct play
- Source-level metrics distinguish conversation from play origins
- UI shows at least: outcome summary, funnel, play performance table
- All metrics endpoints have tests with fixture data
- Metrics are stable (same inputs produce same outputs — no randomness or approximation)

## Out of Scope
- ML-based quality scoring or recommendation ranking
- Scheduled jobs dashboard
- Team-level access control
- Alerting or notifications based on metrics
- Predictive analytics
- Export to external analytics tools

## Risks / Notes
- Metrics only have value after real usage generates enough data. Consider showing "not enough data" states in the UI.
- If source lineage is broken (e.g., insights without run references), metrics will be inaccurate. This depends on PR 3's data integrity.
- Prefer simple, auditable reporting over premature analytics complexity. Every number should be explainable by querying the underlying records.
- Time metrics should exclude outliers or at minimum report p90 alongside median to avoid misleading averages.
