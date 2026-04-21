# Python Expression Style

Demonstrates the project's dense, typed, mathematical coding style. These examples are the canonical reference — when in doubt, match this.

## Compact Assignments and Typed Signatures

Always type args and returns. Combine related assignments. No docstrings when the signature is self-documenting.

```python
def phase_1_test(records_df: pd.DataFrame, bran_config: dict, next_cluster_id: int = None) -> pd.DataFrame:
    ...

def load_encoders(branch: str, ver: int = None, phase: int = 1) -> Allocator:
    ...

def run_sets(sets_list: list = [], experiment_name: str = None) -> None:
    ...
```

## match/case Over if/elif

```python
def get_loss(self, pred_a: torch.Tensor, pred_b: torch.Tensor, Y: torch.Tensor) -> torch.Tensor:
    match self.loss_agg:
        case 'MSE':
            match_mask, n_match_mask = Y.ge(0.0), Y.le(0.0)
            raw_loss = self.criterion(input1=pred_a, input2=pred_b, target=Y)
            raw_loss[n_match_mask] = torch.mul(raw_loss[n_match_mask], 2)
            sq_loss = torch.square(raw_loss)
            loss = sq_loss.mean()
        case 'ME':
            loss = self.criterion(input1=pred_a, input2=pred_b, target=Y).mean()
        case _:
            raise ValueError('Incorrect or no calculation supplied for loss aggregation')
    return loss
```

## Pydantic for Structured Config

```python
class BranConfig(BaseModel):
    bran_class: str
    match_fields: list[str]
    weight_map: dict[str, float]
    threshold: float = 0.95
    depth: int = 2

class ExperimentRun(BaseModel):
    name: str
    sets: list[str]
    bran_configs: dict[str, BranConfig]
    created: datetime = Field(default_factory=datetime.now)
    phase: Literal[1, 2] = 1

class Delivery(BaseModel):
    timestamp: datetime
    dimensions: tuple[int, int]
    model_config = ConfigDict(frozen=True)
```

## Comprehensions and Compact Loops

List comprehensions over explicit loops when the op is a single expression. For multi-step loops, keep the body tight — no blank lines between related operations.

```python
def combination_tensor(embeddings: torch.Tensor, depth: int = 2) -> (torch.Tensor, torch.Tensor):
    n, d = embeddings.shape
    grids = torch.meshgrid(*[torch.arange(n, device=embeddings.device)] * depth, indexing='ij')
    mask = torch.all(torch.stack([grids[k] < grids[k+1] for k in range(depth-1)]), dim=0)
    indices = torch.stack([g[mask] for g in grids], dim=1)
    combos = torch.stack([embeddings[indices[:, k]] for k in range(depth)], dim=1)
    return combos, indices
```

## Compact Loop with Clear Exit

```python
def get_cos_sim(self, pred_a: torch.Tensor, pred_b: torch.Tensor, Y: torch.Tensor) -> bool:
    mask = Y.ge(0.0)
    cs_all = F.cosine_similarity(pred_a.detach(), pred_b.detach())
    precision_t, recall_t, thresholds_t = BPRC(cs_all, mask)
    precision_l, recall_l, thresholds_l = precision_t.tolist(), recall_t.tolist(), thresholds_t.tolist()
    threshold_idx = len(thresholds_l) - 1
    for idx in range(len(thresholds_l)):
        if precision_l[idx] >= 0.99 and recall_l[idx] < 0.99:
            threshold_idx = idx
            break
    self.cluster_threshold = thresholds_l[threshold_idx]
    return recall_l[threshold_idx] > .99
```

## Rationale

- **Density aids readability** for experienced readers. Vertical whitespace that separates related operations forces the eye to scan further for context that belongs together.
- **Typed signatures are documentation.** A function with clear types and a descriptive name needs no docstring.
- **match/case** reads cleaner than if/elif chains and makes the dispatch structure explicit.
- **Pydantic** gives you validation, serialization, and immutability for free — no reason to use raw dicts for structured data.
- **Mathematical elegance** over verbose decomposition — fewer intermediate variables means fewer places for bugs to hide.
