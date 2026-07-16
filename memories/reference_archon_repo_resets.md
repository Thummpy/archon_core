---
name: archon-repo-resets
description: Archon periodically hard-resets project source repos to origin/main, silently wiping uncommitted changes — commit immediately after edits
type: reference
originSessionId: a1982eff-59c2-4aa5-9a4a-444d62fa5f38
---
Archon's repo sync runs `git reset --hard origin/main` on project source directories (visible in reflog as repeated "reset: moving to origin/main"). Any uncommitted working-tree changes are silently destroyed.

**How to apply:** After editing files in any /.archon/workspaces/*/source repo, verify the edits landed and commit promptly (user still reviews pushes per no-auto-merge rules, but don't leave work sitting uncommitted). If edits mysteriously vanish and `git status` is clean, check `git reflog` for a sync reset before assuming a concurrent human edit. Happened 2026-07-09: four dnd-context digest fixes wiped between sessions and had to be re-applied.
