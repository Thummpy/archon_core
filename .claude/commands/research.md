# Research: $ARGUMENTS

Iterative pre-plan research. Your job is to form an understanding, identify your own open questions, and drive toward resolving them with the operator — so that `/plan-feature` receives well-understood requirements. Everything you discuss here stays in the conversation context and carries forward when the operator runs `/plan-feature` next.

## Instructions

You are researching: **$ARGUMENTS**

Do NOT write or modify any files. Do NOT produce a PRP. Do NOT auto-advance to `/plan-feature`.

### Step 1 — Load Context

- If `$ARGUMENTS` contains an issue number (e.g., `#9` or `9`), run `gh issue view <number>` to load the issue title, body, labels, and comments.
- Read `.claude/PLANNING.md`, `.claude/CLAUDE.md`, and `.claude/HANDOFF.md` (if present).
- Spawn sub-agents to search the codebase, open/closed issues, and `.claude/rules/` for anything related to the topic.

### Step 2 — Present Your Understanding

State what you think this problem is, what the solution space looks like, and what constraints apply. Be direct — take a position. This is your working model, not a question list.

### Step 3 — Surface Your Open Questions

Identify where your understanding is incomplete, ambiguous, or assumption-heavy. Categorize as:

- **Unknowns** — things you need to find out
- **Ambiguities** — things that could go multiple ways
- **Assumptions** — things you're assuming that the operator should confirm or reject

Present these to the operator.

### Step 4 — Resolve Iteratively

Drive toward closing each open question:

1. Research it — web search, web fetch, sub-agents for codebase exploration, whatever fits.
2. Propose a position based on what you found.
3. Ask the operator to confirm, reject, or refine.
4. Surface any new questions that emerge.

You drive; the operator steers. Don't wait passively — form opinions, take positions, and let the operator correct you. Never ask the operator something you could have answered by reading the codebase, searching the web, or checking the issue tracker. Do your homework first — only bring questions that genuinely require human judgment or context you can't access.

### Step 5 — Synthesize

When the operator signals research is complete, summarize: what was learned, what decisions were made, and anything unresolved that `/plan-feature` should address.
