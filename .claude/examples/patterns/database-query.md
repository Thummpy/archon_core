# Delta Lake / Spark Query Patterns

This project uses Delta Lake on `hive_metastore` via PySpark — not a traditional RDBMS with an ORM. This pattern file documents safe, efficient data access patterns for the Databricks + Delta Lake stack.

## Parameterized Queries

When using Spark SQL strings, always use parameterized queries to prevent injection.

### PySpark DataFrame API (preferred)

```python
# Good — DataFrame API (no SQL injection risk)
result = spark.table("catalog.raw.train").filter(
    (col("Pclass") == 1) & (col("Survived") == 1)
)

# Good — parameterized SQL
spark.sql(
    "SELECT * FROM catalog.raw.train WHERE Pclass = :pclass",
    args={"pclass": 1},
)

# Bad — string interpolation (SQL injection risk)
spark.sql(f"SELECT * FROM catalog.raw.train WHERE Pclass = {user_input}")
```

## Transaction Boundaries

Delta Lake provides ACID transactions at the table level. Use `overwrite` mode for idempotent pipeline stages.

```python
# Idempotent write — safe to rerun
df.write.format("delta").mode("overwrite").saveAsTable("catalog.features.train")

# Incremental merge — for append-style updates
from delta.tables import DeltaTable
target = DeltaTable.forName(spark, "catalog.tracking.submissions")
target.alias("t").merge(
    new_submissions.alias("s"),
    "t.run_id = s.run_id"
).whenNotMatchedInsertAll().execute()
```

## Connection Pooling

```python
# Always use the active session — never create new SparkSessions
from pyspark.sql import SparkSession
spark = SparkSession.getActiveSession()
if spark is None:
    spark = SparkSession.builder.getOrCreate()
```

## N+1 Query Avoidance

```python
# Bad — reading table multiple times for different filters
pclass_1 = spark.table("catalog.raw.train").filter(col("Pclass") == 1)
pclass_2 = spark.table("catalog.raw.train").filter(col("Pclass") == 2)
pclass_3 = spark.table("catalog.raw.train").filter(col("Pclass") == 3)

# Single read, then filter or group
train = spark.table("catalog.raw.train").cache()
stats_by_class = train.groupBy("Pclass").agg(
    avg("Age").alias("avg_age"),
    sum("Survived").alias("survived_count"),
)
```

## Rationale

- **DataFrame API over raw SQL** reduces injection risk and enables Spark's catalyst optimizer.
- **Overwrite mode** ensures pipeline stages are idempotent — safe to rerun without data corruption.
- **Single SparkSession** avoids resource conflicts in the Databricks runtime.
- **Caching and grouping** prevents redundant reads of the same Delta table.
