---
name: archon-variable-resolution-limits
description: Archon engine can only resolve $nodeId.output.field in prompt nodes — fails in bash nodes and when clauses
type: reference
originSessionId: 9c429c9c-dd50-4868-b711-5c236f9099fb
---
**Archon engine variable substitution has context-dependent behavior:**

- `$ARGUMENTS`, `$ARTIFACTS_DIR`, `$BASE_BRANCH` — work everywhere (bash, prompt, when, script)
- `$nodeId.output` (full output) — works in prompt and bash nodes
- `$nodeId.output.fieldName` (structured field access) — works in **prompt nodes ONLY**

**Fails in:**
- `bash:` nodes — field access resolves to the full output text instead of the specific field
- `when:` clauses — produces `when_condition_parse_error`

**Workarounds:**
1. Move field-access logic into prompt nodes (convert bash to prompt + Bash tool)
2. Use `$ARTIFACTS_DIR` paths for file passing between nodes
3. Consolidate logic that needs structured data into a single prompt node

**Why:** Discovered 2026-06-13 via workflow-editor failure logs. The validate-yaml bash node used `$plan-edits.output.target_path` and received the entire plan-edits response text instead. The copy-if-stock `when: "$resolve-workflow.output.is_stock == true"` logged `when_condition_parse_error`.
