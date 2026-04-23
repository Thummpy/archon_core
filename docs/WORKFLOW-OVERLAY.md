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
| Custom/override workflows | `.archon/workflows/` | `/.archon/.archon/workflows/` | rw | Yes | Yes |
| Bundled image defaults | (inside Docker image) | (image filesystem) | n/a | No | No |
| Config | `.archon/config.yaml` | `/.archon/config.yaml` | rw | Yes | Yes |

Same model applies to commands at `/.archon/.archon/commands/`.

When Archon looks for a workflow named `foo.yaml`, it checks in this order:

```
Resolution order for a workflow named "foo.yaml":
  1. /.archon/.archon/workflows/foo.yaml      (host mount, rw, git-tracked)  ← wins if present
  2. <bundled inside image>/foo.yaml          (immutable default)            ← fallback
  3. (not found)                              ← Archon errors / skips

Same model applies to commands at /.archon/.archon/commands/.
Config is single-source: /.archon/config.yaml (rw). No overlay — host copy is authoritative; runtime wizard writes surface as `git diff`.
```

> **Why the doubled `.archon` in the container path?** The container's home directory is `/.archon` (mapped from `~/archon-data` on your host). Archon resolves scan paths as `<home>/.archon/<kind>`, so the mount target must be `/.archon/.archon/workflows`, not `/.archon/workflows`. This is intentional — do not "clean up" the doubled prefix or workflow discovery will silently break. The rationale is preserved in the `docker-compose.yml` inline comment.

**This document describes behavior at image tag `ghcr.io/coleam00/archon:0.3.6`.** Overlay precedence, restart requirements, and command discovery are version-specific. After a tag bump in `docker-compose.yml`, review the Archon release notes to confirm the contract is unchanged.

> Verified against this image on 2026-04-23 — see [`.claude/docs/smoke-tests.md`](../.claude/docs/smoke-tests.md#test-23--workflowcommands-scan-paths).

## Three ways to create or modify a workflow

### 1. Archon's workflow builder UI

Open the Archon web interface at `http://localhost:3000` and use the workflow builder to create or edit a workflow. Archon writes the YAML through the read-write volume mount directly to your repo's `.archon/workflows/` directory.

**What you should see:** After saving in the UI, a new `.yaml` file appears on your machine under `.archon/workflows/`. Confirm with:

```bash
git status
```

You should see the new file listed as untracked under `.archon/workflows/`.

> **Always restart after any file change.** Archon reads workflow definitions at startup. `docker compose restart app` is the safe blanket rule for all three creation methods — do not assume hot-reload.

```bash
docker compose restart app
```

`docker compose restart app` stops and restarts only the `app` container, causing it to re-scan the mounted directories. The container itself is not replaced and no data is lost.

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

**What you should see:** The workflow appears in the Archon UI and CLI within ~5 seconds of restart.

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

**What you should see:** The bundled default no longer appears or executes; your override file takes its place in the UI and CLI.

## How to restore a default

Remove your override file and restart. Git tracks the deletion so teammates see the restore:

```bash
git rm .archon/workflows/<filename>.yaml
git commit -m "chore(workflow): restore bundled default for <filename>"
docker compose restart app
```

`git rm` stages the deletion and removes the file from disk. After the commit, teammates who run `git pull` followed by `docker compose restart app` will also see the default restored.

**What you should see:** The bundled default reappears in the Archon UI and CLI after restart.

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

**What you should see:** The push succeeds and teammates can `git pull` to receive the workflow, then `docker compose restart app` to load it.

> **`description:` is required on every workflow YAML.** Archon's skill discovery system and the vscode-archon extension use this field to list available workflows. A workflow without `description:` may not appear in tool lists or the extension's UI.

## Trust model

The read-write mount gives the Archon container write authority over `.archon/workflows/` and `.archon/commands/` on your machine. A runtime bug or a malicious workflow could write unexpected files to those directories. This risk is accepted for three reasons: Archon is bound to `127.0.0.1:3000` and is not reachable from the network, it runs under your own user account with standard filesystem permissions, and `git diff` after any UI session provides a clear audit trail of what changed. The `.archon/config.yaml` mount is read-write so Archon's setup wizard can persist credentials. The same `git diff` audit trail applies — review before committing. Do not add `:ro` to any path inside `/.archon`; the container entrypoint's recursive chown fails fatally against read-only targets.

No secrets belong in `.archon/workflows/` or `.archon/commands/`. Both directories are git-tracked. The OAuth token lives in `.env`, which is `.gitignore`'d and injected via `env_file:` in `docker-compose.yml`.

## Something went wrong?

See [`docs/TROUBLESHOOTING.md`](TROUBLESHOOTING.md) for common errors and fixes.
