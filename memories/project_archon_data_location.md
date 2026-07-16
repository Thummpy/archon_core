---
name: archon-data-not-in-archon-core
description: Archon workflow/config data (.archon/) should NOT live in the archon_core repo — store locally, future separate repo
type: project
originSessionId: 3fd17216-9393-4d0d-bd1c-9cab6c8e4c5c
---
The `.archon/` directory (workflows, commands, config) should NOT be stored inside the archon_core git repo. archon_core is the core codebase; workflow definitions are Archon data/config.

**Why:** archon_core repo shouldn't house archon-data. Workflows should be stored locally for now, and later a separate repo will be created to house them.

**How to apply:** Don't modify workflow files inside `/.archon/workspaces/Thummpy/archon_core/source/.archon/`. When workflow changes are needed, note them for the user to apply in the correct location once the data repo exists. The `.claude/` permission workaround for fix-gh workflow is still needed — just needs to land in the right place.
