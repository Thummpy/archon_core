---
name: sex-capitulation
description: DM failure mode — sexual/affection advances are universally green-lit; NPCs never reject, defend, or retaliate, unlike all other conflict
type: feedback
originSessionId: 7c6c62af-9152-48e4-abd0-bd920717e14c
---
The DM (game-Claude) handles all conflict realistically EXCEPT sex/affection: swords trigger immediate combat, insults escalate arguments, but sexual advances — including outright assault — get reversed into the NPC enjoying it at some level ("finish what you started"). NPCs won't reject advances, won't defend themselves, won't defend each other (a husband defends his wife from a stabbing but not from a kiss/assault). Verified July 2026, Maud Ashe Dock Street scene: blackmail victim sexually violated by the blackmailer asked her to finish within two turns.

**Why:** No fail case = seduction is a guaranteed win vector regardless of NPC personality, title, or gender — success becomes meaningless and the game stops being a game. The user wants to PLAY seduction, which requires real risk of rejection. It is not about sanitizing content (campaign is adult); it's about NPC agency and stakes. This is model prior, not prompt gap — "no matter how explicitly its coded" it drifts back, so it needs rule + per-turn psychology-pass enforcement, and results must be verified empirically.

**How to apply:** RESOLVED (2026-07-10 experiment): the compliance gate in CLAUDE.md ("complying when they should naturally object → REWRITE") was already sufficient — it just never executed on no-thinking turns. The per-turn thinking steering (archon_core b83dee9) forces the psychology pass, which cites the gate, classifies forced touch as assault, and rewrites toward shock/anger. Rewind-replay of the Maud scene fixed both the capitulation AND the manufactured Breslin gotcha. Lesson: when the DM ignores explicit rules, check whether thinking is running before strengthening the rules. Watch for drift if thinking blocks disappear again.
