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

<!-- Replace {{INFRA_CONVENTIONS}} with project-specific infrastructure conventions:
     cloud provider, resource naming patterns, required tags (owner, environment, cost-center),
     network topology, security requirements. -->

{{INFRA_CONVENTIONS}}
