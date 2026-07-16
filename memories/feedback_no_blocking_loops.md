---
name: no-blocking-deploy-loops
description: Never use blocking until/while loops to wait for deploys or GH Actions — they spin forever and lock the conversation
type: feedback
originSessionId: 0c3b32f3-03c3-444d-b28a-d794ddea4e0f
---
NEVER use blocking `until`/`while` loops (e.g., `until gh run list ... | grep success; do sleep 10; done`) to wait for GitHub Actions deploys or CI.

**Why:** Every time this has been done, the loop spins forever and locks the Archon thread — the user can't kill it and can't continue the conversation. It has happened multiple times.

**How to apply:** After pushing code, just tell the user "pushed and deploy triggered" and let them check status manually. If you need to verify a deploy, use a single non-blocking `gh run list` check, not a polling loop. Never use Bash `timeout` parameter to make loops "safe" — just don't loop.
