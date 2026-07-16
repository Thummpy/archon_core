---
name: dm-design-rules
description: Campaign-agnostic DM/event-design rules for the D&D game (dnd-context) — profile immutability & drift correction, no minute timers, world must push, owner-relative inventory, meta-fit rewards
type: feedback
originSessionId: dfa7036c-773c-4af4-a033-32007d8e4d94
---
Campaign-agnostic rules for designing/running D&D events for this user. Campaigns, characters, and context-file layouts come and go — apply these to whatever party/campaign is active; never assume specific characters or paths.

1. **Immutable profiles govern, not session drift — two-layer model.** Every NPC splits into two layers. PSYCHOLOGY (OCEAN/thesis) is immutable, sourced from the earliest canonical record (first-appearance profile/episode delta for campaign NPCs; world atlas for world NPCs). STATE is mutable and compiles forward through campaign records (compiled-context files, latest episode delta): possessions, attachments, relationship stances, household membership, standing. "She may pick up a rock and keep it; she may not become someone she isn't." Relationship evolution is STATE: stances warm/cool cumulatively through earned play, but warming toward a PC never converts into deferring to them, imitating them, or adopting their competencies. When session-state contradicts immutable psychology, the PROFILE wins — drift is a DM bug to correct, and re-anchoring must be to the immutable record, never to the drifted portrayal. **Why:** repeated incidents of one scene or status change rewriting characters and destroying what made them interesting; user explicitly articulated the rock metaphor and cited well-maintained NPCs (relationship moved, person stayed put) as the model. **How to apply:** per scene, test "profile speaking, or surroundings?"; when designing events, trace each NPC to their immutable source record AND their compiled current state — use both layers, never blend them.

2. **No in-scene minute timers.** The DM cannot meter minutes honestly ("30 minutes left" → picking up a fork eats 10). Use scene beats (exchanges, toasts, rounds of a social space); day-scale clocks are fine and binding; RAW combat-round durations exempt.

3. **The world must push.** Known failure mode: DM waits reactively, player doesn't know what's next, whole event misfires into a mundane conversation. Events need a lull rule (≈one idle exchange → fire the next queued beat on DM initiative) and NPCs who execute their own schedules regardless of player engagement. Player inaction changes outcomes, never whether the world moves.

4. **Inventory is owner-relative.** NPCs carry/wear wealth appropriate to THEIR station (per economic_reference), never scaled to party balance. Display wealth is characterization; theft is priced by risk/witnesses/aftermath, not by loot rebalancing.

5. **Rewards must fit the PC's operating meta.** Wins are earned, not awarded; no NPC applause; impressed NPCs get more careful, not compliant. For shadow/infiltration-type PCs, visibility, acclaim, and center stage are COSTS, not prizes. Prefer information/access/leverage/irony rewards over gold and standing dumps.

6. **Anti-theme-park.** Failure states are binding — no NPC rescues, no soft landings. Adjudication notes in event files (DC-reduction angles, "elite plays") must never be hinted or steered toward; if the player doesn't author the angle, it doesn't exist. NPC attitudes derive from their own profile and relationship to the PC, not from plot convenience.

7. **Gala post-mortem rules are IN THE REPO (2026-07-09), don't re-propose.** Design set (hook audit, stated motive, threaten player infrastructure, design from the fiction, opposition-is-a-goal, overseed-don't-interlock) lives in `.claude/commands/event-design.md` Design Philosophy; runtime set (defend/concede facts-vs-framing, mundane-patch preference over conspiracy, roll-adjudicates-the-attempt) lives in `.claude/CLAUDE.md` §Adjudication Under Challenge. **How to apply:** when authoring events, the command file carries these; only surface them in conversation if the user asks.
