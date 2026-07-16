---
name: no-temp-in-persistent-config
description: Don't put temporary/migration context in persistent project configs like CLAUDE.md — use GH issues for transient context
type: feedback
originSessionId: da27e23b-36e8-4760-954c-a67532905a25
---
Temporary context (migration plans, "what this repo was") does NOT belong in persistent project configs (.archon/CLAUDE.md, .claude/CLAUDE.md). Once migration is done, it's irrelevant and would just be pollution.
**Why:** User corrected a suggestion to put reconstruction context in CLAUDE.md. Persistent configs should only contain currently-relevant, durable information.
**How to apply:** Use GitHub issues for transient project context. Only put things in CLAUDE.md/rules that will be true and relevant after the current work is done.
