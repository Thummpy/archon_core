import pytest
from unittest.mock import AsyncMock, patch, MagicMock
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

# Import after path is set
import bot


# HIGH: Finding 4 - Error Handling Tests
@pytest.mark.asyncio
async def test_handle_message_load_failure_then_session_init_failure():
    """If load fails AND session init fails, user should see error and return early."""
    mock_message = AsyncMock()
    mock_message.content = "hello"
    mock_thread = AsyncMock()
    mock_thread.id = 123

    with patch('bot.thread_manager.load_context', new_callable=AsyncMock) as mock_load, \
         patch('bot.thread_manager.get_or_create_session_id', new_callable=AsyncMock) as mock_get, \
         patch('bot.claude_runner.run_claude', new_callable=AsyncMock) as mock_claude:

        mock_load.return_value = None  # Load failed
        mock_get.return_value = None   # Session init also failed

        await bot._handle_thread_message(mock_message, mock_thread, "test-channel")

        # Should send error messages
        assert mock_thread.send.call_count == 2
        # First call should be about load failure
        first_call = mock_thread.send.call_args_list[0][0][0]
        assert "couldn't load our conversation history" in first_call
        # Second call should be about session init failure
        second_call = mock_thread.send.call_args_list[1][0][0]
        assert "Failed to initialize session" in second_call

        # Should NOT call Claude
        mock_claude.assert_not_called()


@pytest.mark.asyncio
async def test_handle_message_old_thread_creates_new_session():
    """Old thread (no session_id) should generate UUID and use is_new_session=True."""
    mock_message = AsyncMock()
    mock_message.content = "hello"
    mock_thread = AsyncMock()
    mock_thread.id = 123

    with patch('bot.thread_manager.load_context', new_callable=AsyncMock) as mock_load, \
         patch('bot.thread_manager.get_or_create_session_id', new_callable=AsyncMock) as mock_get, \
         patch('bot.thread_manager.save_context', new_callable=AsyncMock) as mock_save, \
         patch('bot.claude_runner.run_claude', new_callable=AsyncMock) as mock_claude, \
         patch('bot._project_dir_for_channel') as mock_project:

        mock_load.return_value = ([], None)  # Old thread, no session
        mock_get.return_value = "550e8400-e29b-41d4-a716-446655440000"
        mock_claude.return_value = {"text": "response", "trace": []}
        mock_project.return_value = "/test/path"

        await bot._handle_thread_message(mock_message, mock_thread, "test-channel")

        # Should call Claude with new session
        mock_claude.assert_called_once()
        call_kwargs = mock_claude.call_args[1]
        assert call_kwargs['session_id'] == "550e8400-e29b-41d4-a716-446655440000"
        assert call_kwargs['is_new_session'] is True


@pytest.mark.asyncio
async def test_handle_message_existing_session_resumes():
    """Thread with existing session_id should use is_new_session=False."""
    mock_message = AsyncMock()
    mock_message.content = "hello"
    mock_thread = AsyncMock()
    mock_thread.id = 123

    existing_session = "existing-uuid-1234"

    with patch('bot.thread_manager.load_context', new_callable=AsyncMock) as mock_load, \
         patch('bot.thread_manager.save_context', new_callable=AsyncMock) as mock_save, \
         patch('bot.claude_runner.run_claude', new_callable=AsyncMock) as mock_claude, \
         patch('bot._project_dir_for_channel') as mock_project:

        mock_load.return_value = ([{"role": "user", "content": "previous"}], existing_session)
        mock_claude.return_value = {"text": "response", "trace": []}
        mock_project.return_value = "/test/path"

        await bot._handle_thread_message(mock_message, mock_thread, "test-channel")

        # Should call Claude with existing session and resume=True
        mock_claude.assert_called_once()
        call_kwargs = mock_claude.call_args[1]
        assert call_kwargs['session_id'] == existing_session
        assert call_kwargs['is_new_session'] is False


@pytest.mark.asyncio
async def test_handle_message_load_failure_continues_with_fresh_context():
    """Load failure should notify user but continue if session init succeeds."""
    mock_message = AsyncMock()
    mock_message.content = "hello"
    mock_thread = AsyncMock()
    mock_thread.id = 123

    with patch('bot.thread_manager.load_context', new_callable=AsyncMock) as mock_load, \
         patch('bot.thread_manager.get_or_create_session_id', new_callable=AsyncMock) as mock_get, \
         patch('bot.thread_manager.save_context', new_callable=AsyncMock) as mock_save, \
         patch('bot.claude_runner.run_claude', new_callable=AsyncMock) as mock_claude, \
         patch('bot._project_dir_for_channel') as mock_project:

        mock_load.return_value = None  # Load failed
        mock_get.return_value = "new-session-uuid"  # But session init succeeds
        mock_claude.return_value = {"text": "response", "trace": []}
        mock_project.return_value = "/test/path"

        await bot._handle_thread_message(mock_message, mock_thread, "test-channel")

        # Should send warning about load failure
        first_send = mock_thread.send.call_args_list[0][0][0]
        assert "couldn't load our conversation history" in first_send

        # But should still call Claude
        mock_claude.assert_called_once()


@pytest.mark.asyncio
async def test_handle_message_archive_on_threshold():
    """Should archive thread when message count reaches threshold."""
    mock_message = AsyncMock()
    mock_message.content = "hello"
    mock_thread = AsyncMock()
    mock_thread.id = 123

    # Create message history at threshold - 1 (since we add one in handler)
    existing_messages = [{"role": "user", "content": f"msg{i}"} for i in range(499)]

    with patch('bot.thread_manager.load_context', new_callable=AsyncMock) as mock_load, \
         patch('bot.thread_manager.should_archive') as mock_should_archive, \
         patch('bot.config.ARCHIVE_THRESHOLD', 500):

        mock_load.return_value = (existing_messages, "session-id")
        mock_should_archive.return_value = True

        await bot._handle_thread_message(mock_message, mock_thread, "test-channel")

        # Should send archive notification
        archive_msg = mock_thread.send.call_args_list[0][0][0]
        assert "reached" in archive_msg and "archived" in archive_msg

        # Should attempt to archive
        mock_thread.edit.assert_called_once_with(archived=True)


@pytest.mark.asyncio
async def test_handle_message_archive_failure_notifies_user():
    """Archive failure should log error and notify user."""
    import discord

    mock_message = AsyncMock()
    mock_message.content = "hello"
    mock_thread = AsyncMock()
    mock_thread.id = 123
    mock_thread.edit = AsyncMock(side_effect=discord.Forbidden(MagicMock(), "Permission denied"))

    existing_messages = [{"role": "user", "content": f"msg{i}"} for i in range(499)]

    with patch('bot.thread_manager.load_context', new_callable=AsyncMock) as mock_load, \
         patch('bot.thread_manager.should_archive') as mock_should_archive, \
         patch('bot.config.ARCHIVE_THRESHOLD', 500):

        mock_load.return_value = (existing_messages, "session-id")
        mock_should_archive.return_value = True

        await bot._handle_thread_message(mock_message, mock_thread, "test-channel")

        # Should send two messages: archive notification + error
        assert mock_thread.send.call_count == 2
        error_msg = mock_thread.send.call_args_list[1][0][0]
        assert "Could not archive" in error_msg


@pytest.mark.asyncio
async def test_handle_message_timeout_error():
    """Claude timeout should notify user with helpful message."""
    mock_message = AsyncMock()
    mock_message.content = "hello"
    mock_thread = AsyncMock()
    mock_thread.id = 123

    with patch('bot.thread_manager.load_context', new_callable=AsyncMock) as mock_load, \
         patch('bot.claude_runner.run_claude', new_callable=AsyncMock) as mock_claude, \
         patch('bot._project_dir_for_channel') as mock_project:

        mock_load.return_value = ([], "session-id")
        mock_claude.side_effect = TimeoutError("Timeout!")
        mock_project.return_value = "/test/path"

        await bot._handle_thread_message(mock_message, mock_thread, "test-channel")

        # Should send timeout message to user
        timeout_msg = mock_thread.send.call_args[0][0]
        assert "timed out" in timeout_msg


@pytest.mark.asyncio
async def test_handle_message_runtime_error():
    """Claude runtime error should notify user."""
    mock_message = AsyncMock()
    mock_message.content = "hello"
    mock_thread = AsyncMock()
    mock_thread.id = 123

    with patch('bot.thread_manager.load_context', new_callable=AsyncMock) as mock_load, \
         patch('bot.claude_runner.run_claude', new_callable=AsyncMock) as mock_claude, \
         patch('bot._project_dir_for_channel') as mock_project:

        mock_load.return_value = ([], "session-id")
        mock_claude.side_effect = RuntimeError("Claude failed")
        mock_project.return_value = "/test/path"

        await bot._handle_thread_message(mock_message, mock_thread, "test-channel")

        # Should send error message to user
        error_msg = mock_thread.send.call_args[0][0]
        assert "encountered an error" in error_msg


@pytest.mark.asyncio
async def test_handle_message_saves_context_after_success():
    """Should save context with session_id after successful Claude response."""
    mock_message = AsyncMock()
    mock_message.content = "hello"
    mock_thread = AsyncMock()
    mock_thread.id = 123

    with patch('bot.thread_manager.load_context', new_callable=AsyncMock) as mock_load, \
         patch('bot.thread_manager.save_context', new_callable=AsyncMock) as mock_save, \
         patch('bot.claude_runner.run_claude', new_callable=AsyncMock) as mock_claude, \
         patch('bot._project_dir_for_channel') as mock_project:

        mock_load.return_value = ([], "session-id")
        mock_claude.return_value = {"text": "response", "trace": []}
        mock_project.return_value = "/test/path"

        await bot._handle_thread_message(mock_message, mock_thread, "test-channel")

        # Should save context with both messages and session_id
        mock_save.assert_called_once()
        call_args = mock_save.call_args
        messages = call_args[0][1]
        session_id = call_args[1]['session_id']

        assert len(messages) == 2  # user + assistant
        assert messages[0]["role"] == "user"
        assert messages[1]["role"] == "assistant"
        assert session_id == "session-id"
