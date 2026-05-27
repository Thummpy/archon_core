# Workflow Overlay Model

## What you need before starting

- Docker installed and running on your machine (see [docs/SETUP.md](SETUP.md) for installation steps)
- This repository cloned to your machine
- A `.env` file in the repo root with `CLAUDE_CODE_OAUTH_TOKEN` set (copy from `.env.example` and fill in your token)
- The Archon container running: `docker compose up -d`

## Why this exists

Archon ships with built-in default workflows and commands baked into its Docker image. Teams need to override those defaults and add custom ones without forking the image. The overlay model lets both coexist: Archon's defaults remain available, and any file you place in `.archon/workflows/` silently takes priority over the default with the same filename.

## The three layers

Archon resolves workflows and commands from three sources, in priority order:

| Layer | Host path | Container path | Mode | Git-tracked | Archon can write |
|---|---|---|---|---|---|
| Custom/override workflows | `.archon/workflows/` | `/.archon/workflows/` | rw | Yes | Yes |
| Bundled image defaults | (inside Docker image) | (image filesystem) | n/a | No | No |
| Config | `.archon/config.yaml` | `/.archon/config.yaml` | rw | Yes | Yes |

Same model applies to commands at `/.archon/commands/`.

When Archon looks for a workflow named `foo.yaml`, it checks in this order:

```
Resolution order for a workflow named "foo.yaml":
  1. /.archon/workflows/foo.yaml              (host mount, rw, git-tracked)  ← wins if present
  2. <bundled inside image>/foo.yaml          (immutable default)            ← fallback
  3. (not found)                              ← Archon errors / skips

Same model applies to commands at /.archon/commands/.
Config is single-source: /.archon/config.yaml (rw). No overlay — host copy is authoritative; runtime wizard writes surface as `git diff`.
```

**This document describes behavior at image tag `ghcr.io/coleam00/archon:0.3.12`.** Overlay precedence, restart requirements, and command discovery are version-specific. After a tag bump in `docker-compose.yml`, review the Archon release notes to confirm the contract is unchanged.

> Verified against `0.3.6` on 2026-04-23 (Tests 23, 24, 30) and `0.3.12` on 2026-05-20 (Test 30) — see [`.claude/docs/smoke-tests.md`](../.claude/docs/smoke-tests.md).

## Three ways to create or modify a workflow

### 1. Archon's workflow builder UI

Open the Archon web interface at `https://localhost` and use the workflow builder to create or edit a workflow (`Workflows → + New Workflow`). When the save completes fully, Archon writes the YAML through the read-write volume mount to your repo's `.archon/workflows/` directory **and** stores a record in SQLite (`~/archon-data/archon.db`).

**What you should see:** After a successful save, a new `.yaml` file appears on your machine under `.archon/workflows/`. Confirm with:

```bash
git status
```

You should see the new file listed as untracked under `.archon/workflows/`.

> **Caveat — the save requires a working Claude API connection.** Archon makes an outbound call to the Claude API as part of the save process (model validation or workflow compilation). If that call hangs — for example, because `CLAUDE_CODE_OAUTH_TOKEN` is expired or not usable by Archon — the save stalls at ~89%. In this state, the YAML file is written to disk (and visible via `git status`) but the SQLite record is not written, so the workflow does not appear in Archon's Workflows UI page. If your save stalls, check your token first (see issue #25) and re-save after refreshing it.

> **In 0.3.12, YAML files appear in the Web UI after restart.** Archon discovers YAML files in `/.archon/workflows/` at startup — a file written to disk appears in the Workflows Web UI after `docker compose restart app` (confirmed in `.claude/docs/smoke-tests.md` Test 30). If a builder save stalls at ~89% (OAuth issue), the YAML is still written to disk — a restart will surface it in the Web UI even without a complete save.

After a successful save, stage and commit the YAML file to share it with the team:

```bash
git add .archon/workflows/
git commit -m "feat(workflow): add <name> workflow"
```

### 2. Hand-written YAML + restart

1. Create a `.yaml` or `.yml` file under `.archon/workflows/`:

```bash
# Example
touch .archon/workflows/my-workflow.yaml
```

2. Open the file in your editor and add at minimum a `description:` field at the top level — this field is **required** for skill discoverability.

3. Restart the container to pick up the change:

```bash
docker compose restart app
```

**What you should see:** The YAML file is present in the container filesystem (bind-mount confirmed), and the workflow **appears in the Workflows Web UI** at `https://localhost/workflows`. In 0.3.12, Archon discovers YAML files at startup — confirmed in [`.claude/docs/smoke-tests.md`](../.claude/docs/smoke-tests.md) Test 30. The `archon` CLI binary is not in the container PATH by design (the upstream Dockerfile does not add it).

### 3. Claude Code with the Archon skill

Ask Claude Code to author a workflow using the Archon skill. The agent writes the `.yaml` file under `.archon/workflows/` and reports the file path on completion.

**What you should see:** Same outcome as method 2 — the file exists on disk and is visible in `git status`. Restart the container after the agent finishes:

```bash
docker compose restart app
```

## How to "delete" a bundled default

Archon's built-in defaults live inside the Docker image and cannot be removed — the image is immutable. To suppress a default, create a same-named file in `.archon/workflows/` that overrides it with a stub:

```yaml
description: Disabled — suppresses the bundled default of the same name.
steps: []
```

Then restart the container:

```bash
docker compose restart app
```

**What you should see:** The override file is present in the container filesystem and takes priority for workflow execution (the bundled default is shadowed). In 0.3.12, the stub also appears in the Workflows Web UI — Archon discovers YAML files at startup (see [`.claude/docs/smoke-tests.md`](../.claude/docs/smoke-tests.md) Test 30).

## How to restore a default

Remove your override file and restart. Git tracks the deletion so teammates see the restore:

```bash
git rm .archon/workflows/<filename>.yaml
git commit -m "chore(workflow): restore bundled default for <filename>"
docker compose restart app
```

`git rm` stages the deletion and removes the file from disk. After the commit, teammates who run `git pull` followed by `docker compose restart app` will also see the default restored.

**What you should see:** The override file is removed from the container filesystem and the bundled default is no longer suppressed for execution. In 0.3.12, the stub entry also disappears from the Workflows Web UI after restart — Archon only discovers YAML files that exist on disk at startup.

## Git workflow after building in the UI

When you create a workflow in the UI, the file lands on your host filesystem but is not yet committed. Run these steps to save and share it with the team:

1. Check what was created:

```bash
git status
```

**What you should see:** New `.yaml` files under `.archon/workflows/` listed as untracked.

2. Review the generated YAML before committing:

```bash
git diff .archon/workflows/
```

**What you should see:** The full YAML content of the new workflow. Confirm the `description:` field is present and non-empty — it is required.

3. Stage and commit:

```bash
git add .archon/workflows/
git commit -m "feat(workflow): add <name> workflow"
```

4. Push to share with the team:

```bash
git push
```

**What you should see:** The push succeeds and teammates can `git pull` to receive the YAML file. After `docker compose restart app`, the workflow is in the container filesystem and **appears in the Workflows Web UI** — in 0.3.12 Archon discovers YAML files at startup (see [`.claude/docs/smoke-tests.md`](../.claude/docs/smoke-tests.md) Test 30). The `archon` CLI binary is not in the container PATH by design. Verify delivery with `docker compose exec app ls /.archon/workflows/`.

> **`description:` is required on every workflow YAML.** Archon's skill discovery system and the vscode-archon extension use this field to list available workflows. A workflow without `description:` may not appear in tool lists or the extension's UI.

## Trust model

The read-write mount gives the Archon container write authority over `.archon/workflows/` and `.archon/commands/` on your machine. A runtime bug or a malicious workflow could write unexpected files to those directories. This risk is accepted for three reasons: Archon is bound to `127.0.0.1:3000` and is not reachable from the network, it runs under your own user account with standard filesystem permissions, and `git diff` after any UI session provides a clear audit trail of what changed. The `.archon/config.yaml` mount is read-write so Archon's setup wizard can persist credentials. The same `git diff` audit trail applies — review before committing. Do not add `:ro` to any path inside `/.archon`; the container entrypoint's recursive chown fails fatally against read-only targets.

No secrets belong in `.archon/workflows/` or `.archon/commands/`. Both directories are git-tracked. The OAuth token lives in `.env`, which is `.gitignore`'d and injected via `env_file:` in `docker-compose.yml`.

## Built-in workflow audit (verified 2026-05-22)

Archon 0.3.12 ships 20 built-in workflows. Two were audited against this team's development workflow:

### `archon-piv-loop`

A 5-phase interactive loop: EXPLORE → PLAN → IMPLEMENT → VALIDATE → FINALIZE. This is a superset of the Plan-Execute-Validate concept — it adds an upfront exploration phase and an explicit finalization phase. **No custom Plan-Execute-Validate workflow is needed.** Use `archon-piv-loop` from the Web UI for full-cycle feature development.

### `archon-workflow-builder`

Creates a custom workflow YAML file via AI-guided intent extraction — you describe what you want a workflow to do, and Archon generates the YAML. This **complements** the DLC authoring flow (which covers general feature development in Claude Code) rather than replacing it. Use `archon-workflow-builder` when you want to create a new reusable Archon workflow for a specific project pattern.

### Decision: `.archon/workflows/` reserved for team-specific workflows

No custom workflows duplicate the 20 built-ins. `.archon/workflows/` is reserved for team-specific workflows that extend the built-ins — workflows that encode team conventions, project-specific patterns, or custom automation not covered by the defaults. Use **distinct filenames** (not starting with `archon-`) to avoid shadowing built-ins.

## Something went wrong?

See [`docs/TROUBLESHOOTING.md`](TROUBLESHOOTING.md) for common errors and fixes.
