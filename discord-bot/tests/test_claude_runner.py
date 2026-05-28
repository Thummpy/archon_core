import pytest
from unittest.mock import AsyncMock, patch
import asyncio
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from claude_runner import run_claude


# HIGH: Finding 3 - CLI Command Construction Tests
@pytest.mark.asyncio
@patch('claude_runner.asyncio.create_subprocess_exec', new_callable=AsyncMock)
async def test_run_claude_new_session_command(mock_exec):
    """New session should use --session-id flag."""
    mock_proc = AsyncMock()
    mock_proc.communicate.return_value = (b"response", b"")
    mock_proc.returncode = 0
    mock_exec.return_value = mock_proc

    await run_claude(
        prompt="hello",
        session_id="550e8400-e29b-41d4-a716-446655440000",
        is_new_session=True
    )

    # Verify command contains --session-id, not --resume
    args, kwargs = mock_exec.call_args
    cmd = args
    assert "claude" in cmd
    assert "--session-id" in cmd
    assert "550e8400-e29b-41d4-a716-446655440000" in cmd
    assert "--resume" not in cmd


@pytest.mark.asyncio
@patch('claude_runner.asyncio.create_subprocess_exec', new_callable=AsyncMock)
async def test_run_claude_resume_session_command(mock_exec):
    """Resume session should use --resume flag."""
    mock_proc = AsyncMock()
    mock_proc.communicate.return_value = (b"response", b"")
    mock_proc.returncode = 0
    mock_exec.return_value = mock_proc

    await run_claude(
        prompt="hello",
        session_id="550e8400-e29b-41d4-a716-446655440000",
        is_new_session=False
    )

    args, kwargs = mock_exec.call_args
    cmd = args
    assert "--resume" in cmd
    assert "550e8400-e29b-41d4-a716-446655440000" in cmd
    assert "--session-id" not in cmd


@pytest.mark.asyncio
@patch('claude_runner.asyncio.create_subprocess_exec', new_callable=AsyncMock)
async def test_run_claude_no_session_command(mock_exec):
    """No session should use neither --session-id nor --resume."""
    mock_proc = AsyncMock()
    mock_proc.communicate.return_value = (b"response", b"")
    mock_proc.returncode = 0
    mock_exec.return_value = mock_proc

    await run_claude(prompt="hello", session_id=None, is_new_session=False)

    args, kwargs = mock_exec.call_args
    cmd = args
    assert "--session-id" not in cmd
    assert "--resume" not in cmd


@pytest.mark.asyncio
@patch('claude_runner.asyncio.create_subprocess_exec', new_callable=AsyncMock)
async def test_run_claude_invalid_state_is_new_without_session_id(mock_exec):
    """is_new_session=True with session_id=None should use one-off mode (current behavior)."""
    mock_proc = AsyncMock()
    mock_proc.communicate.return_value = (b"response", b"")
    mock_proc.returncode = 0
    mock_exec.return_value = mock_proc

    # This is the invalid state - test documents current behavior
    await run_claude(prompt="hello", session_id=None, is_new_session=True)

    args, kwargs = mock_exec.call_args
    cmd = args
    # Currently falls through to one-off mode
    assert "--session-id" not in cmd
    assert "--resume" not in cmd


@pytest.mark.asyncio
@patch('claude_runner.asyncio.create_subprocess_exec', new_callable=AsyncMock)
async def test_run_claude_with_project_dir(mock_exec):
    """Should pass project_dir as cwd to subprocess."""
    mock_proc = AsyncMock()
    mock_proc.communicate.return_value = (b"response", b"")
    mock_proc.returncode = 0
    mock_exec.return_value = mock_proc

    await run_claude(prompt="hello", project_dir="/path/to/project")

    args, kwargs = mock_exec.call_args
    assert kwargs['cwd'] == "/path/to/project"


@pytest.mark.asyncio
@patch('claude_runner.asyncio.create_subprocess_exec', new_callable=AsyncMock)
async def test_run_claude_file_not_found_error(mock_exec):
    """Should raise RuntimeError with clear message when Claude CLI not found."""
    mock_exec.side_effect = FileNotFoundError()

    with pytest.raises(RuntimeError, match="Claude CLI is not installed or not in PATH"):
        await run_claude(prompt="hello")


@pytest.mark.asyncio
@patch('claude_runner.asyncio.create_subprocess_exec', new_callable=AsyncMock)
async def test_run_claude_permission_error(mock_exec):
    """Should raise RuntimeError when Claude CLI lacks execute permissions."""
    mock_exec.side_effect = PermissionError()

    with pytest.raises(RuntimeError, match="Claude CLI lacks execute permissions"):
        await run_claude(prompt="hello")


@pytest.mark.asyncio
@patch('claude_runner.asyncio.create_subprocess_exec', new_callable=AsyncMock)
@patch('claude_runner.asyncio.wait_for', new_callable=AsyncMock)
async def test_run_claude_timeout_error(mock_wait_for, mock_exec):
    """Should raise TimeoutError when Claude takes too long."""
    mock_proc = AsyncMock()
    mock_exec.return_value = mock_proc
    mock_wait_for.side_effect = asyncio.TimeoutError()

    with pytest.raises(TimeoutError, match="Claude did not respond within"):
        await run_claude(prompt="hello")

    # Should kill the process
    mock_proc.kill.assert_called_once()


@pytest.mark.asyncio
@patch('claude_runner.asyncio.create_subprocess_exec', new_callable=AsyncMock)
async def test_run_claude_nonzero_exit_code(mock_exec):
    """Should raise RuntimeError when Claude CLI exits with non-zero code."""
    mock_proc = AsyncMock()
    mock_proc.communicate.return_value = (b"", b"error message")
    mock_proc.returncode = 1
    mock_exec.return_value = mock_proc

    with pytest.raises(RuntimeError, match="Claude CLI exited with code 1"):
        await run_claude(prompt="hello")


@pytest.mark.asyncio
@patch('claude_runner.asyncio.create_subprocess_exec', new_callable=AsyncMock)
async def test_run_claude_success_returns_text(mock_exec):
    """Should return text on success."""
    mock_proc = AsyncMock()
    mock_proc.communicate.return_value = (b"Claude response text", b"")
    mock_proc.returncode = 0
    mock_exec.return_value = mock_proc

    result = await run_claude(prompt="hello")

    assert result["text"] == "Claude response text"
    assert result["trace"] == []


@pytest.mark.asyncio
@patch('claude_runner.asyncio.create_subprocess_exec', new_callable=AsyncMock)
async def test_run_claude_stderr_warning_on_success(mock_exec):
    """Should log warning if stderr present on success."""
    mock_proc = AsyncMock()
    mock_proc.communicate.return_value = (b"response", b"warning message")
    mock_proc.returncode = 0
    mock_exec.return_value = mock_proc

    # Should not raise, but should log warning
    result = await run_claude(prompt="hello")

    assert result["text"] == "response"


@pytest.mark.asyncio
@patch('claude_runner.asyncio.create_subprocess_exec', new_callable=AsyncMock)
async def test_run_claude_os_error(mock_exec):
    """Should raise RuntimeError with helpful message on OSError."""
    mock_exec.side_effect = OSError(28, "No space left on device")

    with pytest.raises(RuntimeError, match="Could not spawn Claude CLI process"):
        await run_claude(prompt="hello")
