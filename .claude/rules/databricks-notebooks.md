---
paths:
  - "src/eda/**"
  - "notebooks/**"
---

# Databricks Notebook Conventions

## File Format

Databricks notebook-format Python files must start with `# Databricks notebook source` and use `# COMMAND ----------` cell separators.

## Self-Containment

EDA notebooks must be self-contained: each notebook reads its own data from Delta, produces its own outputs, and does not depend on variables set by other notebooks.

## sys.path Setup: Dual-Context Pattern

Scripts and notebooks that import from shared modules (e.g., `from common.config import ...`) need the parent `src/` directory on `sys.path`. The setup differs between execution contexts and **both must be handled**:

- **spark_python_task (jobs):** `__file__` is defined. Derive `src/` from the file path.
- **Interactive notebooks:** `__file__` is NOT defined. `inspect.currentframe().f_code.co_filename` returns `<command-XXX>`, not a real path. Use `dbutils` to get the notebook's workspace path instead.

The combined pattern:

```python
import os, sys

_src_dir = None
if globals().get("__file__"):
    _src_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
else:
    try:
        # dbutils is a Databricks-injected global
        _nb_path = (
            dbutils.notebook.entry_point  # noqa: F821
            .getDbutils().notebook().getContext()
            .notebookPath().get()
        )
        # notebookPath returns without /Workspace prefix
        # Filesystem paths require /Workspace prefix
        # Navigate up two levels: eda/<name> → src/
        _src_dir = os.path.dirname(os.path.dirname(f"/Workspace{_nb_path}"))
    except Exception:
        pass

if _src_dir and _src_dir not in sys.path:
    sys.path.insert(0, _src_dir)
```

This must appear in the first cell, before any project imports. The `inspect` frame trick does NOT work for interactive notebooks — always use `dbutils` as the fallback.

## Concurrent Delta Table Writes

When multiple notebooks write to the same shared Delta table (e.g., an EDA summaries table), use the idempotent write pattern to avoid `ProtocolChangedException`:

```python
# 1. Ensure table exists (safe for concurrent execution)
spark.sql(f"""
    CREATE TABLE IF NOT EXISTS {table_name} (
        notebook STRING NOT NULL,
        finding_type STRING NOT NULL,
        ...
    ) USING DELTA
""")

# 2. Clear this notebook's previous rows
spark.sql(f"DELETE FROM {table_name} WHERE notebook = '{NOTEBOOK_NAME}'")

# 3. Append new rows
sdf.write.mode("append").saveAsTable(table_name)
```

Never use `mode("overwrite")` on a shared table — it will destroy other notebooks' rows.

## Ruff and Mypy Configuration

Notebooks with sys.path setup before imports will trigger E402 (module-level import not at top of file). Add per-file ignores in `ruff.toml`:

```toml
[lint.per-file-ignores]
"src/eda/*.py" = ["E402"]
```

Notebooks using pandas, matplotlib, and scipy in ways that don't type-check cleanly should be excluded from strict mypy checking:

```ini
[mypy-eda.*]
ignore_errors = true
```
