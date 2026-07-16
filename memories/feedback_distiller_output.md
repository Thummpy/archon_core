---
name: distiller-output-contract
description: Transcript distiller must output ONE episode JSON file in a campaign subfolder, never modify existing files
type: feedback
originSessionId: f85b78dd-005c-450b-8e97-83f9bd56d22d
---
The distiller workflow MUST produce a single episode file (e.g., `campaign_barthen/barthen_ep1.json`) inside the campaign directory. That file contains novel profiles, profile diffs to existing profiles, thread cards, and a timeline. Nothing else.

**Why:** The current workflow greedily merges facts into every registered card and overwrites existing files. This is catastrophically wrong — it touched out-of-scope files (campaign_threads_vigil.json), resurrected deleted files (campaign_threads_barthen.json), created unwanted standalone profiles, and modified the atlas. User was furious.

**How to apply:** When fixing or rebuilding the distiller workflow, the output contract is: one folder per campaign, one JSON file per episode, zero modifications to any existing file. The episode file contains deltas and new content only — never full card rewrites.
