# Databricks CLI Patterns

Correct CLI usage patterns for Databricks workspaces using DAB (Declarative Automation Bundles) and Databricks CLI v0.280+.

## Authentication & Profiles

### Profile configuration (`~/.databrickscfg`)

**PAT-based (persistent):**
```ini
[${profile}]
host = https://${workspace_id}.cloud.databricks.com
token = dapi_xxxxx
```

**OAuth (session-based):**
```bash
databricks auth login --host https://${workspace_id}.cloud.databricks.com --profile ${profile}
```

Always restrict permissions on the config file: `chmod 600 ~/.databrickscfg`

### Bundle vs standalone commands

**Bundle commands** (`databricks bundle ...`) read the profile from `databricks.yml` — no `--profile` flag needed:

```bash
databricks bundle validate --target dev
databricks bundle summary --target dev
databricks bundle deploy --target dev
```

**Standalone commands** (`databricks clusters ...`, `databricks catalogs ...`, etc.) are NOT bundle-aware and MUST include `--profile`:

```bash
databricks clusters list --profile ${profile}
databricks catalogs list --profile ${profile}
```

### Get current user (useful for scripting)

```bash
databricks current-user me --profile ${profile} --output json | jq -r '.userName'
```

Store in a variable for dynamic path construction:
```bash
CURRENT_USER=$(databricks current-user me --profile ${profile} --output json | jq -r '.userName')
```

## Critical Syntax Rules

### Positional arguments, not flags

The CLI uses positional args for primary identifiers. Using flags for them will fail:

```bash
# WRONG — "accepts 1 arg(s), received 2"
databricks schemas list --catalog-name my_catalog
databricks jobs get --job-id 123

# CORRECT — positional
databricks schemas list my_catalog
databricks jobs get 123
```

### JSON input: inline vs file

Inline JSON for simple payloads:
```bash
databricks jobs submit --json '{"run_name": "test", ...}'
```

File reference with `@` prefix for complex payloads (avoids shell quoting issues):
```bash
databricks jobs submit --json @config.json
```

### Output format

Some CLI commands return a text table by default, not JSON. When piping to `python3` or `jq`, always use `--output json`:

```bash
# WRONG — default output is a text table, json.load() will fail
databricks clusters list-node-types --profile ${profile} | python3 -c "..."

# CORRECT — explicit JSON output
databricks clusters list-node-types --profile ${profile} --output json | python3 -c "..."
```

## Spark Version String Format

The ML runtime version string includes a `cpu` or `gpu` segment. A common mistake is omitting it:

```
# CORRECT
16.4.x-cpu-ml-scala2.12

# WRONG — missing cpu/gpu segment
16.4.x-ml-scala2.12
```

Discovery command: `databricks clusters spark-versions --profile ${profile} | grep "${version}"`

## Bundle Validation & Summary

### Validate bundle config

```bash
databricks bundle validate --target ${target}
```

Returns "Validation OK!" on success. Catches: invalid YAML structure, missing required fields, naming convention violations (e.g., `mode: development` without username in prefix).

### Check effective resource names (after presets applied)

```bash
databricks bundle summary --target ${target}
```

Shows the final resource names after `presets.name_prefix` is applied. Useful for verifying naming conventions without deploying.

### `presets.name_prefix` applies to these resource types

| Resource Type | Prefix Applied? |
|---|---|
| `resources.clusters` | YES |
| `resources.jobs` | YES |
| `resources.pipelines` | YES |

## Job Definition Gotchas

### `python_file` paths are relative to the YAML file, not the bundle root

When a job definition is in `resources/jobs/my_job.yml`, the `python_file` path is resolved relative to `resources/jobs/`, not the project root:

```yaml
# WRONG — resolves to resources/jobs/src/my_script.py
spark_python_task:
  python_file: ./src/my_script.py

# CORRECT — navigate up from resources/jobs/ to project root
spark_python_task:
  python_file: ../../src/my_script.py
```

### `existing_cluster_id` is task-level, not job-level

```yaml
# CORRECT — at task level
tasks:
  - task_key: my_task
    existing_cluster_id: ${resources.clusters.my_cluster.cluster_id}
    spark_python_task:
      python_file: ../../src/my_script.py
      source: WORKSPACE
```

### `source: WORKSPACE` is required

Without it, Databricks looks for the file on DBFS instead of deployed workspace files.

## Single-Node Cluster Configuration

Three settings are required — missing any one may cause validation errors or unexpected behavior:

```yaml
num_workers: 0
spark_conf:
  "spark.databricks.cluster.profile": "singleNode"
  "spark.master": "local[*, 4]"    # 4 = parallelism, match vCPU count
custom_tags:
  "ResourceClass": "SingleNode"
```

`data_security_mode: "NONE"` is valid and appropriate for hive_metastore (non-UC) workspaces.

## Deploying Files to the Workspace

### Bundle sync: which files land in the workspace

By default, `databricks bundle deploy` only syncs files that are **referenced by a DAB resource** (e.g., a job's `python_file`). Interactive notebooks, utility scripts, or any file not referenced by a job will NOT be deployed unless explicitly included.

Add a `sync.include` block to `databricks.yml`:

```yaml
sync:
  include:
    - src/notebooks/*.py    # Interactive notebooks
    - src/utils/*.py        # Shared utility scripts
```

Without this, deploying the bundle will succeed but unreferenced files will not appear in the workspace.

### Where deployed files live

Bundle files are deployed to:

```
/Workspace/Users/${user}/.bundle/${bundle_name}/${target}/files/...
```

Notebooks with the `# Databricks notebook source` header render as interactive notebooks in the workspace UI.

### Cluster management

Clusters defined via `resources.clusters` do NOT auto-start on `databricks bundle deploy`. They are created in a stopped state. Start explicitly:

```bash
databricks clusters start ${cluster_id} --profile ${profile}
```

If the cluster is already running, this is a no-op.

### Direct workspace operations (outside bundles)

For debugging, one-off uploads, or inspecting what's deployed:

```bash
databricks workspace list /Users/${user}/ --profile ${profile}
databricks workspace import /Users/${user}/notebook --file local.py --language PYTHON --format SOURCE --overwrite --profile ${profile}
databricks workspace export /Users/${user}/notebook --format SOURCE --profile ${profile}
databricks workspace delete /Users/${user}/notebook --profile ${profile}
```

## Running Notebooks and Scripts via CLI

### Submit a notebook as a one-time run

```bash
databricks jobs submit --profile ${profile} --no-wait --json '{
  "run_name": "my_test_run",
  "tasks": [{
    "task_key": "my_task",
    "existing_cluster_id": "${cluster_id}",
    "notebook_task": {
      "notebook_path": "/Users/${user}/.bundle/${bundle}/${target}/files/src/my_notebook",
      "source": "WORKSPACE"
    }
  }]
}'
```

For complex payloads, use a file: `databricks jobs submit --profile ${profile} --no-wait --json @run_config.json`

Key details:
- Use the **tasks array** structure with `notebook_task` inside. Flat `notebook_task` at the root is rejected.
- `--no-wait` returns immediately with a `run_id`. Without it, CLI blocks until completion (can be 10+ minutes including cluster startup).
- The notebook path does NOT include the `/Workspace` prefix or the `.py` extension.

### Check run status and poll to completion

```bash
databricks jobs get-run ${run_id} --profile ${profile} --output json
```

Parse with: `d['state']['life_cycle_state']` (PENDING, RUNNING, TERMINATED, INTERNAL_ERROR) and `d['state']['result_state']` (SUCCESS, FAILED).

Poll loop for monitoring:
```bash
while true; do
  STATE=$(databricks jobs get-run ${run_id} --profile ${profile} --output json | jq -r '.state.life_cycle_state')
  echo "Status: $STATE"
  [[ "$STATE" == "TERMINATED" || "$STATE" == "INTERNAL_ERROR" ]] && break
  sleep 10
done
```

### Get error details from a failed run

The parent run ID often has a generic error message. Get the **task-level run ID** first, then fetch its output:

```bash
# Step 1: get task run ID from parent run
databricks jobs get-run ${parent_run_id} --profile ${profile} --output json
# → d['tasks'][0]['run_id'] = TASK_RUN_ID

# Step 2: get the actual error trace
databricks jobs get-run-output ${task_run_id} --profile ${profile} --output json
# → d['error'] and d['error_trace'] contain the stack trace
```

### Job management commands

```bash
databricks jobs list --profile ${profile}
databricks jobs get ${job_id} --profile ${profile}
databricks jobs list-runs --job-id ${job_id} --limit 5 --profile ${profile}
databricks jobs run-now ${job_id} --profile ${profile}            # Trigger existing job
databricks jobs delete ${job_id} --profile ${profile}
```

### Cluster startup time

If the cluster is TERMINATED, it takes 3-5 minutes to start. Runs will show `RUNNING` state during startup — poll `get-run` periodically rather than assuming immediate execution.

## Concurrent Delta Table Writes

Multiple notebooks or jobs writing to the same **new** Delta table simultaneously causes `ProtocolChangedException` ("multiple writers writing to an empty directory"). This happens because each writer races to create the table via `saveAsTable`.

**Fix:** Pre-create the table with `CREATE TABLE IF NOT EXISTS` before writing:

```python
spark.sql(f"""
    CREATE TABLE IF NOT EXISTS {table_name} (
        col1 STRING NOT NULL,
        col2 DOUBLE
    ) USING DELTA
""")
spark.sql(f"DELETE FROM {table_name} WHERE source = '{my_source}'")
sdf.write.mode("append").saveAsTable(table_name)
```

`CREATE TABLE IF NOT EXISTS` is idempotent and safe for concurrent execution. The subsequent `DELETE` + `APPEND` pattern handles concurrent writers correctly because Delta supports concurrent appends to an existing table.

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `accepts 1 arg(s), received 2` | Using flags instead of positional args | `databricks jobs get 123` not `--job-id 123` |
| `unknown flag: --json-file` | Wrong flag name | Use `--json @file.json` |
| `ProtocolChangedException` | Concurrent writers creating same new table | Pre-create with `CREATE TABLE IF NOT EXISTS` |
| `file ... not found` (bundle validate) | `python_file` path relative to YAML, not bundle root | Use `../../src/...` from `resources/jobs/` |
| `DBFS path not found` | Missing `source: WORKSPACE` | Add `source: WORKSPACE` to task config |

## Iterative Development on Databricks

**Code that runs on Databricks must be developed iteratively: deploy, run, inspect, then build the next piece.** Do not write an entire pipeline or notebook suite in one pass and assume it will work.

### The pattern

1. **Write the minimum viable first cell/step** — imports, data loading, one simple operation (e.g., print row counts, show schema). This validates that deployment, imports, and data access all work.
2. **Deploy and run it** — `databricks bundle deploy` then submit via CLI or run interactively.
3. **Inspect actual output** — check for errors via `get-run-output`, verify data shapes and values match expectations.
4. **Build the next piece based on real results** — let actual data patterns, column types, null distributions, and value ranges inform what to write next. Don't assume.
5. **Repeat** until the full implementation is complete.

### Why this matters

- **Environment differences are invisible until runtime.** Import paths, library versions, Delta table schemas, and Spark behavior can differ between local dev and Databricks in ways that lint and type checks cannot catch.
- **Data assumptions are often wrong.** Column types may differ from documentation. Null patterns may be unexpected. Value distributions affect which statistical methods are appropriate. Only running the code against real data reveals this.
- **Errors compound.** A broken import in cell 1 means cells 2-8 were wasted effort. A wrong column name in step 2 means steps 3-10 need rework. Catching errors early keeps the feedback loop tight.

### Anti-pattern: batch-write-then-pray

Writing multiple notebooks or pipeline stages in one pass, deploying, and running them all simultaneously produces:
- Identical bugs replicated across all files (e.g., an import setup that doesn't work in the target environment)
- Race conditions from concurrent execution that wouldn't occur in sequential development
- No opportunity for earlier results to inform later analysis

Even when domain knowledge is strong enough to predict outcomes, the mechanical act of running code on Databricks catches environmental and infrastructure issues that no amount of local validation can surface.
