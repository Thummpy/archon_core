import pytest
import json
from pathlib import Path
from unittest.mock import AsyncMock, patch
import uuid
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from thread_manager import get_or_create_session_id, load_context, save_context


# CRITICAL: Finding 1 - Session ID Generation Tests
@pytest.mark.asyncio
async def test_get_or_create_returns_existing_session_id():
    """Should return existing session ID if present."""
    existing_uuid = str(uuid.uuid4())
    with patch('thread_manager.load_context', new_callable=AsyncMock) as mock_load:
        mock_load.return_value = ([], existing_uuid)

        result = await get_or_create_session_id(thread_id=123)

        assert result == existing_uuid
        mock_load.assert_called_once_with(123)


@pytest.mark.asyncio
async def test_get_or_create_generates_uuid_for_new_thread():
    """Should generate valid UUID for thread without session_id."""
    with patch('thread_manager.load_context', new_callable=AsyncMock) as mock_load:
        mock_load.return_value = ([], None)

        result = await get_or_create_session_id(thread_id=123)

        assert result is not None
        uuid.UUID(result)  # Validates UUID format (raises ValueError if invalid)


@pytest.mark.asyncio
async def test_get_or_create_returns_none_when_load_fails():
    """Should return None if load_context fails (corrupt file)."""
    with patch('thread_manager.load_context', new_callable=AsyncMock) as mock_load:
        mock_load.return_value = None

        result = await get_or_create_session_id(thread_id=123)

        assert result is None


@pytest.mark.asyncio
async def test_get_or_create_uuid_uniqueness():
    """Should generate different UUIDs for different threads."""
    with patch('thread_manager.load_context', new_callable=AsyncMock) as mock_load:
        mock_load.return_value = ([], None)

        uuid1 = await get_or_create_session_id(thread_id=1)
        uuid2 = await get_or_create_session_id(thread_id=2)

        assert uuid1 != uuid2


@pytest.mark.asyncio
async def test_get_or_create_with_preloaded_result():
    """Should use preloaded result instead of loading again."""
    preloaded = ([], None)
    with patch('thread_manager.load_context', new_callable=AsyncMock) as mock_load:
        result = await get_or_create_session_id(thread_id=123, preloaded_result=preloaded)

        # Should NOT call load_context when preloaded_result is provided
        mock_load.assert_not_called()
        assert result is not None
        uuid.UUID(result)  # Should be valid UUID


# HIGH: Finding 2 - Return Type Change Tests
@pytest.mark.asyncio
async def test_load_context_new_thread_returns_empty(tmp_path, monkeypatch):
    """New thread (no file) should return ([], None)."""
    monkeypatch.setattr('thread_manager.THREADS_DIR', str(tmp_path))

    result = await load_context(thread_id=999)

    assert result == ([], None)


@pytest.mark.asyncio
async def test_load_context_old_thread_without_session_id(tmp_path, monkeypatch):
    """Old thread file (no session_id key) should return (messages, None)."""
    monkeypatch.setattr('thread_manager.THREADS_DIR', str(tmp_path))
    thread_file = tmp_path / "123.json"
    thread_file.write_text(json.dumps({
        "thread_id": 123,
        "messages": [{"role": "user", "content": "hello"}]
        # No session_id key
    }))

    result = await load_context(thread_id=123)

    assert result == ([{"role": "user", "content": "hello"}], None)


@pytest.mark.asyncio
async def test_load_context_with_session_id(tmp_path, monkeypatch):
    """New format thread with session_id should return both."""
    monkeypatch.setattr('thread_manager.THREADS_DIR', str(tmp_path))
    thread_file = tmp_path / "123.json"
    session_uuid = "550e8400-e29b-41d4-a716-446655440000"
    thread_file.write_text(json.dumps({
        "thread_id": 123,
        "session_id": session_uuid,
        "messages": [{"role": "user", "content": "hello"}]
    }))

    result = await load_context(thread_id=123)

    assert result == ([{"role": "user", "content": "hello"}], session_uuid)


@pytest.mark.asyncio
async def test_load_context_corrupt_json_returns_none(tmp_path, monkeypatch):
    """Corrupt JSON should return None (signals error)."""
    monkeypatch.setattr('thread_manager.THREADS_DIR', str(tmp_path))
    thread_file = tmp_path / "123.json"
    thread_file.write_text("{not valid json")

    result = await load_context(thread_id=123)

    assert result is None


@pytest.mark.asyncio
async def test_load_context_missing_messages_key(tmp_path, monkeypatch):
    """JSON without 'messages' key should return ([], session_id)."""
    monkeypatch.setattr('thread_manager.THREADS_DIR', str(tmp_path))
    thread_file = tmp_path / "123.json"
    thread_file.write_text(json.dumps({
        "thread_id": 123,
        "session_id": "550e8400-e29b-41d4-a716-446655440000"
        # Missing "messages" key
    }))

    result = await load_context(thread_id=123)

    assert result == ([], "550e8400-e29b-41d4-a716-446655440000")


# MEDIUM: Finding 5 - Round-Trip Tests
@pytest.mark.asyncio
async def test_save_and_load_round_trip_with_session(tmp_path, monkeypatch):
    """Save with session_id should load back identically."""
    monkeypatch.setattr('thread_manager.THREADS_DIR', str(tmp_path))

    messages = [{"role": "user", "content": "hello"}]
    session_id = "550e8400-e29b-41d4-a716-446655440000"

    await save_context(thread_id=123, messages=messages, session_id=session_id)
    result = await load_context(thread_id=123)

    assert result == (messages, session_id)


@pytest.mark.asyncio
async def test_save_and_load_round_trip_without_session(tmp_path, monkeypatch):
    """Save with session_id=None should load back as (messages, None)."""
    monkeypatch.setattr('thread_manager.THREADS_DIR', str(tmp_path))

    messages = [{"role": "user", "content": "hello"}]

    await save_context(thread_id=123, messages=messages, session_id=None)
    result = await load_context(thread_id=123)

    assert result == (messages, None)


@pytest.mark.asyncio
async def test_save_and_load_round_trip_multiple_messages(tmp_path, monkeypatch):
    """Save multiple messages and ensure all are preserved."""
    monkeypatch.setattr('thread_manager.THREADS_DIR', str(tmp_path))

    messages = [
        {"role": "user", "content": "hello"},
        {"role": "assistant", "content": "hi there"},
        {"role": "user", "content": "how are you?"}
    ]
    session_id = str(uuid.uuid4())

    await save_context(thread_id=456, messages=messages, session_id=session_id)
    result = await load_context(thread_id=456)

    assert result == (messages, session_id)
