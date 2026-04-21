# Project Planning

<!-- This file captures architecture, constraints, and design decisions.
     It is read by the AI agent at the start of every session (via .claude/CLAUDE.md).
     Replace all {{PLACEHOLDER}} markers during project initialization. -->

## Project Overview

<!-- Describe the project's purpose, the team or users it serves, and the type of project
     (greenfield build, migration, modernization, data pipeline, etc.). -->

{{PROJECT_OVERVIEW}}

## Architecture

<!-- Describe the system's high-level architecture: components, how they communicate,
     and the deployment model. Reference .claude/docs/architecture.md for diagrams and details. -->

{{ARCHITECTURE}}

## Tech Stack

<!-- List languages, frameworks, databases, message queues, cloud services, and infrastructure
     tooling. Include version constraints where they matter. -->

{{TECH_STACK}}

## Design Decisions

<!-- Record key architectural and technical choices made during initialization or development.
     Each entry should state the decision, why it was made, and what alternatives were rejected.
     For formal decisions, create an ADR in .claude/docs/adr/ and link it here. -->

{{DESIGN_DECISIONS}}

## Constraints

<!-- Document hard constraints: security requirements, performance targets,
     deployment restrictions, network boundaries, approved libraries, etc. -->

{{CONSTRAINTS}}

## Style & Conventions

<!-- Project-specific patterns beyond the universal coding standards in .claude/CLAUDE.md.
     Examples: API versioning strategy, state management approach, error code taxonomy,
     branch naming conventions, PR size limits. -->

{{STYLE_CONVENTIONS}}

## Out of Scope

<!-- Explicit boundaries to prevent scope creep. List features, integrations, or changes
     that are intentionally excluded from this project. -->

{{OUT_OF_SCOPE}}
