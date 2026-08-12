import logging
import re

logger = logging.getLogger("discord-bot.models")

MODEL_TIERS = {
    "large": "claude-opus-5",
    "medium": "claude-sonnet-5",
}

_BARE_ALIASES = {"opus", "sonnet", "haiku"}


def resolve_model(model: str) -> str:
    """
    Resolve a model tier name to a pinned model ID.

    - Tier names (large, medium) → pinned model IDs from MODEL_TIERS
    - Raw model IDs → pass through unchanged
    - Bare aliases (opus, sonnet, haiku) → pass through with warning

    Returns the resolved model ID string.
    """
    # Check if it's a tier name
    if model in MODEL_TIERS:
        resolved = MODEL_TIERS[model]
        logger.info("Resolved model tier=%s to model=%s", model, resolved)
        return resolved

    # Check if it's a bare alias (after stripping thinking suffix)
    model_without_suffix = re.sub(r'\[.*\]$', '', model).lower()
    if model_without_suffix in _BARE_ALIASES:
        logger.warning(
            "Bare alias model=%s detected. This resolves via SDK and may drift. "
            "Use tier names (large, medium) or full model IDs (claude-opus-5).",
            model
        )

    # Pass through raw model IDs unchanged
    return model
