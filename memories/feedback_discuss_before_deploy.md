---
name: discuss-before-deploy
description: Stop chain-deploying edits to live infra (bot/game runtime) — talk the design through and get sign-off first
type: feedback
originSessionId: 7c6c62af-9152-48e4-abd0-bd920717e14c
---
Do not run away with changes to live infrastructure (discord bot, claude_runner, game session handling) — no edit→push→deploy→edit→push cycles. Present the design, talk it through, get explicit sign-off, THEN implement in one clean change.

**Why:** 2026-07-10, I deployed the style-aware thinking switch in three rapid commits (537bf98, ad1ede5) while the user was mid-game. User: "stop running away with changes and posting them then edit and post and edit and post... I haven't followed all that you just did... if there's an interruption in this thread I'm stuck. can't revert, don't know what to fix." Undocumented rapid iteration on live systems leaves the user unable to recover without me.

**How to apply:** For bot/runtime/deploy changes: discuss first, single reviewed change after approval. Always state the revert path (exact commits). Quick read-only investigation is fine; mutations need sign-off. Rewinds of the game session on explicit request are exempt (established operation).
