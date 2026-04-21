---
paths:
  - "**/*.py"
---

# Python Style — Dense, Typed, Mathematical

Operator's native coding style. These rules apply to all Python in this project.

## Type Discipline

- Type hints on ALL function args and returns, no exceptions.
- Pydantic `BaseModel` for any structured config or data contract.

## Expression Style

- Combine related assignments on one line: `n, d = embeddings.shape`
- List comprehensions over explicit loops when the op is a single expression.
- Chain `.method().method()` when it reads naturally.
- Tensor/vector ops over Python loops — always.
- Mathematical elegance over verbose "readable" decomposition.

## Control Flow

- `match`/`case` over `if`/`elif` chains.

## Vertical Density

- No blank lines between related operations inside a function.
- Blank line ONLY between logically distinct blocks.
- Minimal vertical space — density aids readability for experienced readers.

## Documentation

- No docstrings on obvious functions — the typed signature IS the documentation.
- Docstrings only when domain context is non-obvious. Explain WHY, not WHAT.
