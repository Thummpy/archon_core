# Infrastructure Issues & Gotchas

Known issues and workarounds in the Archon GCP infrastructure. This document captures operational knowledge that isn't obvious from the code alone.

## Terraform Heredoc Escaping

**Problem:** Terraform's `<<-SCRIPT` heredoc interprets `${...}` as Terraform interpolation, which conflicts with bash variable expansion like `${var}`.

**Root Cause:** Terraform heredocs process `${ }` sequences as template expressions. Plain `$VAR` and `$(command)` pass through unmodified, but `${VAR}` collides with Terraform syntax.

**Solution Applied:** The startup script in `terraform/modules/archon-vm/main.tf` uses two approaches:
- Plain `$VAR` syntax for bash variables (no braces) — works without escaping
- `$${VAR}` to produce a literal `${VAR}` in the rendered script where brace expansion is needed

```hcl
# In terraform/modules/archon-vm/main.tf startup_script heredoc:
startup_script = <<-SCRIPT
  USERNAME="${var.ssh_username}"   # Terraform variable — interpolated at plan time
  usermod -aG docker "$USERNAME"  # Plain $VAR — passed through to bash as-is
SCRIPT
```

**Guidance:** When editing the startup script, use `$VAR` instead of `${VAR}` for bash variables. If you must use `${...}` in bash, escape it as `$${...}` so Terraform emits a literal `${...}`.

## Startup Script Timing

**Problem:** After `docker compose up -d`, containers need time to initialize before health checks pass. The Discord bot in particular requires its entrypoint to validate tokens and start the Python process.

**Root Cause:** Docker Compose returns immediately after starting containers. Services with health checks (30s interval, 15s start period) may not be healthy yet when subsequent verification commands run.

**Solution Applied:** The startup script in `terraform/modules/archon-vm/main.tf:177-178` includes a 30-second sleep after `docker compose up -d`:

```bash
echo "→ Waiting for containers to stabilize (30s)..."
sleep 30
```

The deploy workflow (`.github/workflows/deploy.yml:98-99`) uses a 15-second sleep since containers are restarting (not cold-starting).

**Guidance:** The 30s delay is conservative but reliable for initial provisioning. Do not remove it. If adding new services with longer startup times, increase the delay proportionally.

## Docker Config Permissions

**Problem:** Docker creates `~/.docker/config.json` owned by root when Docker commands first run via `sudo` or during the startup script, causing permission errors for the unprivileged user on subsequent runs.

**Root Cause:** The Terraform startup script runs as root. When Docker commands execute, Docker writes `~/.docker/` using root's resolved `$HOME` (which points to the deploy user's home after `HOME="$USER_HOME"`). The resulting files are owned by root, blocking the deploy user from running Docker commands later.

**Solution Applied:** Both the startup script and deploy workflow fix permissions proactively:

```bash
# terraform/modules/archon-vm/main.tf:175
chown -R "$USERNAME:$USERNAME" "$USER_HOME/.docker" 2>/dev/null || true

# .github/workflows/deploy.yml:80
sudo chown -R "$(whoami):$(whoami)" ~/.docker 2>/dev/null || true
```

The `2>/dev/null || true` suppresses errors when `~/.docker/` doesn't exist yet.

**Guidance:** Always run the `chown` fix before any `docker compose` command in new scripts or workflows. The `|| true` guard makes it safe to run unconditionally.
