# Sharing Workflows

## What you need before starting

- Archon running on your machine (see [docs/SETUP.md](SETUP.md) if you have not completed first-time setup)
- This repository cloned to your machine
- Git configured with your name and email (`git config user.name` and `git config user.email`)

> This guide focuses on the team git workflow for sharing custom workflows. For the full technical details of how Archon discovers and overrides workflows — including the three-layer resolution model and container path layout — see [docs/WORKFLOW-OVERLAY.md](WORKFLOW-OVERLAY.md).

## How workflow sharing works

Workflow YAML files live in `.archon/workflows/` inside this repo. Because that directory is git-tracked, sharing a workflow with the team is the same as sharing any code change: commit the file, push, and teammates pull.

After a teammate runs `git pull`, they restart the Archon container:

```bash
docker compose restart app
```

Archon reads `.archon/workflows/` through a bind mount — the directory on your machine is directly visible inside the container. After restart, new YAML files are present in the container filesystem. See [docs/WORKFLOW-OVERLAY.md](WORKFLOW-OVERLAY.md) for the full overlay resolution model.

> **YAML files are not discoverable after `git pull` in Archon 0.3.6.** After `git pull + docker compose restart app`, the workflow YAML is delivered to the container filesystem (bind-mount confirmed) but is not listed by any available interface: the Web UI reads from SQLite and does not scan user YAML files at startup; the `archon` CLI binary is not in the container PATH (`archon workflow list` exits with code 127). Confirmed in [`.claude/docs/smoke-tests.md`](../.claude/docs/smoke-tests.md) Test 30.

## Getting workflows from your team

When a teammate pushes new or updated workflows:

1. Pull the latest changes:

```bash
git pull
```

**What you should see:** Git lists the files that changed. New or updated `.yaml` files under `.archon/workflows/` confirm the workflow was received.

2. Restart the container to pick up the new files:

```bash
docker compose restart app
```

**What you should see:**

```
✔ Container archon-app  Started
```

The restart takes about 5 seconds. Archon reads the updated overlay on startup.

3. Confirm the workflow was delivered to the container:

```bash
docker compose exec app ls /.archon/.archon/workflows/
```

**What you should see:** The new workflow YAML filename appears in the directory listing. This confirms the bind-mount delivered the file.

> **The Web UI and CLI will not list the workflow in Archon 0.3.6.** The Workflows page reads from SQLite (not YAML files), and the `archon` CLI binary is not in the container PATH — `archon workflow list` exits with code 127. Container filesystem listing is the only way to verify delivery. Confirmed in [`.claude/docs/smoke-tests.md`](../.claude/docs/smoke-tests.md) Test 30.

## Contributing a workflow

There are three ways to author a workflow: the Archon workflow builder UI, hand-written YAML, or Claude Code. For detailed authoring instructions, see [docs/WORKFLOW-OVERLAY.md — Three ways to create or modify a workflow](WORKFLOW-OVERLAY.md#three-ways-to-create-or-modify-a-workflow).

After authoring a workflow by any method, share it with the team by committing and pushing the YAML file:

```bash
git status                          # confirm the new file appears under .archon/workflows/
git add .archon/workflows/
git commit -m "feat(workflow): add <name> workflow"
git push
```

**What you should see:** The push succeeds. Teammates who run `git pull` followed by `docker compose restart app` will have the YAML file delivered to the container filesystem. In Archon 0.3.6, the workflow is not discoverable via the Web UI or CLI — see [`.claude/docs/smoke-tests.md`](../.claude/docs/smoke-tests.md) Test 30 for the confirmed finding.

> **`description:` is required on every workflow YAML.** Archon's skill discovery system uses this field. A workflow without `description:` may not appear in tool lists or the Web UI.

> **Do not place secrets in `.archon/workflows/` or `.archon/commands/`.** Both directories are git-tracked. Credentials belong in `.env`, which is `.gitignore`'d.

### If the workflow was built in the Archon UI

After saving in the builder, the YAML file appears in `.archon/workflows/` on your host machine. Stage and commit it:

```bash
git status                          # verify the file is listed as untracked
git diff .archon/workflows/         # review the YAML before committing
git add .archon/workflows/
git commit -m "feat(workflow): add <name> workflow"
git push
```

> **Save stalling at ~89%?** The OAuth token in `.env` is expired. The YAML file is written to disk but the SQLite record is not written — the workflow appears in `git status` but not in the Workflows Web UI. Refresh the token by running `./scripts/setup-oauth.sh`, then retry the save. See [Something went wrong?](#something-went-wrong) for details.

## Filename override behavior

A file in `.archon/workflows/` with the same name as one of Archon's bundled defaults takes precedence — the custom version runs, the bundled one is ignored.

Use **distinct filenames** for new custom workflows to avoid accidental shadowing. Archon's built-in workflows use names starting with `archon-` (for example, `archon-assist`, `archon-fix-github-issue`). A name that does not start with `archon-` avoids collisions.

To intentionally suppress a built-in, create a same-named stub:

```yaml
description: Disabled — suppresses the bundled default of the same name.
steps: []
```

Restart and commit:

```bash
docker compose restart app
git add .archon/workflows/<filename>.yaml
git commit -m "chore(workflow): suppress built-in <filename>"
git push
```

**What you should see:** After the restart, `docker compose exec app archon workflow list` no longer shows the suppressed workflow. The stub override takes its place.

For the full overlay resolution order and instructions on restoring a suppressed default, see [docs/WORKFLOW-OVERLAY.md](WORKFLOW-OVERLAY.md).

## Something went wrong?

See [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common errors and fixes.

### Workflow not appearing after git pull + restart

In Archon 0.3.6, a workflow YAML delivered by `git pull` will not appear in the Web UI (reads from SQLite) or via `archon workflow list` (binary not in container PATH). This is confirmed behavior — see [`.claude/docs/smoke-tests.md`](../.claude/docs/smoke-tests.md) Test 30. Container filesystem listing (`docker compose exec app ls /.archon/.archon/workflows/`) is the only way to verify the file was delivered.

If the YAML file is not present in the container filesystem at all, check:

1. The YAML file exists on disk: `ls .archon/workflows/`
2. The container was restarted after the pull: `docker compose restart app`
3. The YAML has a `description:` field: open the file and check the top-level keys

### Save stalling at ~89% in the workflow builder

The OAuth token in `.env` is expired. The YAML file is written to disk (visible in `git status`) but the SQLite record is not written, so the workflow does not appear in the Workflows UI page. Run `./scripts/setup-oauth.sh` to refresh the token, then retry the save in the builder.
