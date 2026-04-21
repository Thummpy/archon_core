# Architecture

<!-- This file is populated during project initialization.
     Replace each {{PLACEHOLDER}} with project-specific content.
     Delete these HTML comments after initialization. -->

## System Overview

<!-- Provide a high-level description of the system and its purpose.
     Include a Mermaid architecture diagram showing major components and their relationships. -->

{{SYSTEM_OVERVIEW}}

```mermaid
graph TD
    {{ARCHITECTURE_DIAGRAM}}
```

## Component Descriptions

<!-- List each major component/service/module with:
     - Name and responsibility
     - Technology used
     - Key interfaces it exposes or consumes -->

{{COMPONENT_DESCRIPTIONS}}

## Data Flow

<!-- Describe how data moves through the system:
     - Entry points (APIs, event streams, file ingestion)
     - Processing/transformation stages
     - Storage layers (databases, caches, object stores)
     - Output channels (APIs, reports, notifications) -->

{{DATA_FLOW}}

## External Dependencies

<!-- List all external systems this project integrates with:
     - Third-party APIs and services
     - Shared internal services
     - Data sources and sinks
     - Authentication/authorization providers
     Include connection details (not credentials) and SLA expectations. -->

{{EXTERNAL_DEPENDENCIES}}

## Infrastructure & Deployment Model

<!-- Describe the deployment topology:
     - Cloud provider and regions
     - Compute model (containers, serverless, VMs)
     - Networking (VPCs, load balancers, DNS)
     - CI/CD pipeline overview
     Reference .claude/docs/deployment.md for operational procedures. -->

{{INFRASTRUCTURE_DEPLOYMENT}}

## Security Architecture

<!-- Document security controls:
     - Authentication and authorization model
     - Data encryption (at rest and in transit)
     - Network security (firewalls, WAF, private endpoints)
     - Secrets management approach
     - Security requirements
     - Logging strategy -->

{{SECURITY_ARCHITECTURE}}
