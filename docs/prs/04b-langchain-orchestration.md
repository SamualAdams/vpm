# PR 4b: LangChain orchestration

## Summary
Implement the LangChain chains that power transcript analysis, question investigation, and insight-to-action generation. Wire them into the chat and MCP tool endpoints from PR 4a.

## Why
The tools and routes exist (PR 4a) but return placeholder responses. This PR adds the intelligence: LLM-powered analysis that reads board and repo state, generates insights with evidence and confidence, and proposes typed actions.

## Scope

### LangChain chains (`vpm/chains/`)

**Transcript analysis chain** (`transcript_chain.py`)
- Input: raw transcript text + current board state + recent repo activity
- Steps:
  1. Parse transcript for discussion topics, decisions, and follow-ups
  2. Cross-reference mentioned work items, people, and deliverables against Azure DevOps board
  3. Identify gaps: untracked follow-ups, stale items discussed as active, decisions that imply board changes
- Output: thread with insights (each citing specific transcript excerpts and board entities)

**Question investigation chain** (`question_chain.py`)
- Input: user question + current board state + recent repo activity
- Steps:
  1. Interpret the question in context of the project
  2. Query relevant board items and repo data
  3. Synthesize an answer with supporting evidence
- Output: response text + insights (if the investigation reveals actionable observations)

**Insight-to-action chain** (`action_chain.py`)
- Input: one or more insights
- Steps:
  1. For each insight, determine if a concrete board action is warranted
  2. Generate typed action proposals with complete payloads matching the taxonomy from PR 3
  3. Include "what changes" description: what the board looks like before and after
- Output: list of recommended_actions saved to DB

### Integration
- Wire transcript chain into `stage_transcript` (MCP tool) and `POST /api/transcript`
- Wire question chain into WebSocket `/ws/chat` and `POST /api/chat`
- Wire action chain to run automatically after insights are generated (opt-in, configurable)
- Wire play invocation: `invoke_play` maps `chain_name` from play definition to the corresponding chain

### Structured output
- Use LangChain's structured output with Pydantic models to ensure LLM responses parse into domain objects
- Insight model: `observation`, `evidence` (list of entity references), `confidence` (0–1)
- Action model: `action_type` (enum), `payload` (matching taxonomy schema), `rationale`

### Citation extraction
- When the LLM references work items, PRs, or commits, capture as citation records linked to the thread
- Citations include entity type, entity ID, Azure DevOps URL, and the context in which they were cited

### Prompt management
- Prompts stored as files in `vpm/chains/prompts/` (plain text with variable placeholders)
- System prompts establish the assistant's role as a project manager analyzing board state
- Few-shot examples for each chain type to guide output format

## Acceptance Criteria
- Submit a transcript → thread created with insights citing specific transcript excerpts and board items
- Ask a question via chat → receive an investigated answer with evidence
- Insights automatically generate recommended actions with correct typed payloads
- Invoke a play by name → corresponding chain executes and produces results
- Citations are saved and queryable by thread
- Structured output parsing produces valid domain objects (no untyped JSON blobs)
- Chain failures are handled gracefully: run marked as `failed`, error recorded, user notified
- All chains have tests (using mocked LLM responses)

## Out of Scope
- UI for any of this (PR 5)
- Scheduled/automatic play execution
- Advanced heuristics beyond what the LLM can infer from context
- Token-by-token streaming to the browser (future enhancement)
- Fine-tuning or custom model training

## Risks / Notes
- LLM output quality depends heavily on prompt design — expect iteration on prompts after initial integration
- Structured output parsing can fail if the LLM doesn't follow the schema. Use LangChain's retry/repair mechanisms.
- Chain execution involves multiple LLM calls and Azure API calls — total latency per transcript may be 10-30 seconds. The WebSocket and MCP interfaces should handle this gracefully (progress indicators, not timeouts).
- Mocked LLM tests validate parsing and integration, not output quality. Output quality requires manual evaluation.
