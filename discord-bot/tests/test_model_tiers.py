import pytest
import logging
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from model_tiers import resolve_model, MODEL_TIERS


def test_resolve_tier_large():
    """Tier name 'large' resolves to claude-opus-5."""
    assert resolve_model("large") == "claude-opus-5"


def test_resolve_tier_medium():
    """Tier name 'medium' resolves to claude-sonnet-5."""
    assert resolve_model("medium") == "claude-sonnet-5"


def test_resolve_raw_model_id_passthrough():
    """Raw model ID with thinking suffix passes through unchanged."""
    assert resolve_model("claude-opus-4-6[1m]") == "claude-opus-4-6[1m]"


def test_resolve_raw_model_id_no_suffix():
    """Raw model ID without thinking suffix passes through unchanged."""
    assert resolve_model("claude-opus-4-6") == "claude-opus-4-6"


def test_bare_alias_warns(caplog):
    """Bare alias 'opus' passes through but logs warning."""
    with caplog.at_level(logging.WARNING):
        result = resolve_model("opus")
    assert result == "opus"
    assert "Bare alias" in caplog.text
    assert "opus" in caplog.text


def test_bare_alias_with_suffix_warns(caplog):
    """Bare alias with thinking suffix passes through but logs warning."""
    with caplog.at_level(logging.WARNING):
        result = resolve_model("opus[1m]")
    assert result == "opus[1m]"
    assert "Bare alias" in caplog.text


def test_bare_alias_sonnet_warns(caplog):
    """Bare alias 'sonnet' passes through but logs warning."""
    with caplog.at_level(logging.WARNING):
        result = resolve_model("sonnet")
    assert result == "sonnet"
    assert "Bare alias" in caplog.text


def test_bare_alias_haiku_warns(caplog):
    """Bare alias 'haiku' passes through but logs warning."""
    with caplog.at_level(logging.WARNING):
        result = resolve_model("haiku")
    assert result == "haiku"
    assert "Bare alias" in caplog.text


def test_unknown_string_passthrough(caplog):
    """Unknown model ID passes through without warning."""
    with caplog.at_level(logging.WARNING):
        result = resolve_model("claude-fable-5[1m]")
    assert result == "claude-fable-5[1m]"
    assert "Bare alias" not in caplog.text


def test_resolve_tier_case_insensitive():
    """Tier lookup is case-insensitive — 'Large', 'LARGE' resolve like 'large'."""
    assert resolve_model("Large") == "claude-opus-5"
    assert resolve_model("LARGE") == "claude-opus-5"
    assert resolve_model("MEDIUM") == "claude-sonnet-5"


def test_tier_names_are_stable():
    """MODEL_TIERS contains exactly the expected tier names."""
    assert set(MODEL_TIERS.keys()) == {"large", "medium"}
