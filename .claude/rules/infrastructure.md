---
paths:
  - "**/terraform/**"
  - "**/infrastructure/**"
  - "**/deploy/**"
  - "**/*.tf"
  - "**/Dockerfile*"
  - "**/docker-compose*"
---

# Infrastructure Conventions

## General IaC Practices

- All infrastructure is defined as code. No manual resource creation.
- Use modules/reusable components to avoid duplication.
- Pin provider and module versions explicitly.
- Separate environment configuration from infrastructure definitions (use variables/tfvars, not hardcoded values).
- Store state remotely with locking enabled.

## Security

- No secrets, credentials, or keys in infrastructure code.
- Use IAM roles and service accounts over long-lived credentials.
- Apply least-privilege access to all resources.
- Encrypt data at rest and in transit by default.

## Containers

- Use specific image tags, never `latest`.
- Run containers as non-root users.
- Keep images minimal — use multi-stage builds where appropriate.
- Do not store application secrets in Dockerfiles or image layers.

## Naming & Tagging

- Container name: `archon-app` (and `archon-postgres` if using `with-db` profile)
- Network: `archon-network` (bridge)
- Host-path volume: `~/archon-data` → `/.archon` in container
- Postgres volume (optional profile only): `archon_postgres_data` (named volume)
- Archon port: `127.0.0.1:3000:3000` (localhost only)
- All containers use `restart: unless-stopped`
- DNS override: `dns: [8.8.8.8, 8.8.4.4]` on app container (required for external API calls from within container)
- Backup files: `backups/archon-YYYYMMDD-HHMMSS.db`
