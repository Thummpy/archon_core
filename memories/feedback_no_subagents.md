---
name: no-subagents-without-permission
description: NEVER spawn subagents (Task/Agent tool) unless explicitly instructed by user or required by a workflow definition
type: feedback
originSessionId: 833d6a4d-896e-41c1-8dc8-3cfcc92a92f4
---
NEVER use subagents unless specifically asked/told to, or the workflow definition dictates it. Default to reading, grepping, and analyzing IN the current context.

**Why:** User wants full visibility and control over what's being read/analyzed. Subagents hide the reading from the main context and can miss things or fabricate. When the user says "read up on THIS context," they mean read the actual files in the main thread — not delegate.

**How to apply:** Do not call the Agent tool for research, exploration, summarization, or "big file" chunking. Read files directly with Read/Grep/Bash. Only spawn a subagent when the user says so explicitly, or when a workflow YAML mandates it. If a task feels too large for main context, ASK before delegating.
