---
name: dnd-context-architecture-pivot
description: Major restructure from Claude.ai game + Claude Code dev tooling → Claude Code as the game engine with Archon as dev layer
type: project
originSessionId: da27e23b-36e8-4760-954c-a67532905a25
---
As of 2026-05-26, dnd-context is pivoting from its original architecture to a new one.

**Old**: `.claude/` was a dev harness (commands, scripts, tests) for building/maintaining context files. Game ran in Claude.ai. Runtime context (profiles, atlases, skills, rules) lived outside `.claude/` and was manually uploaded to Claude.ai. Constant confusion between dev context and runtime context. Harness modifying itself was problematic.

**New**: Archon replaces the old `.claude/` dev harness (sits above projects). Claude Code replaces Claude.ai as the game runtime. The repo becomes the gameboard — runtime context moves INTO `.claude/` so Claude Code natively loads it. No more dual-context collision.

**Why:** Claude Code tested well as game engine. Old architecture had dev/runtime confusion, self-modifying harness problems, and the AI layer locked into each repo. Archon solves the dev tooling problem from outside.

**How to apply:** All future work should target the new architecture. Old `.claude/` dev tooling (commands/, scripts/, tests/, docs/) gets removed. Context files restructured into `.claude/` for Claude Code consumption. Archon workflows handle development tasks.
