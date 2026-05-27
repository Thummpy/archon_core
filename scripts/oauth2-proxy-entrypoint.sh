#!/usr/bin/env bash
set -euo pipefail

# Validate OAUTH_EMAIL is set
if [ -z "${OAUTH_EMAIL:-}" ]; then
  echo "ERROR: OAUTH_EMAIL environment variable is not set." >&2
  echo "Set it in .env to specify which email(s) can access Archon." >&2
  echo "Example: OAUTH_EMAIL=your-email@gmail.com" >&2
  exit 1
fi

# Basic email format validation
if ! echo "${OAUTH_EMAIL}" | grep -qE '^[^@]+@[^@]+\.[^@]+$'; then
  echo "ERROR: OAUTH_EMAIL does not appear to be a valid email: ${OAUTH_EMAIL}" >&2
  exit 1
fi

# Write email to whitelist file
EMAILS_FILE="/tmp/oauth2-emails.txt"
echo "[oauth2-proxy] Allowing access for: ${OAUTH_EMAIL}" >&2
echo "${OAUTH_EMAIL}" > "${EMAILS_FILE}"

# Verify file write succeeded
if [ ! -s "${EMAILS_FILE}" ]; then
  echo "ERROR: Failed to write allowed email to ${EMAILS_FILE}" >&2
  echo "  OAUTH_EMAIL='${OAUTH_EMAIL}'" >&2
  echo "  Check disk space, filesystem permissions, and OAUTH_EMAIL format" >&2
  exit 1
fi

# Start oauth2-proxy
exec /bin/oauth2-proxy --authenticated-emails-file="${EMAILS_FILE}"

# This line only executes if exec fails
echo "ERROR: Failed to exec /bin/oauth2-proxy" >&2
echo "  Binary: /bin/oauth2-proxy" >&2
echo "  Args: --authenticated-emails-file=${EMAILS_FILE}" >&2
echo "  Check that oauth2-proxy is installed in the container image" >&2
exit 1
