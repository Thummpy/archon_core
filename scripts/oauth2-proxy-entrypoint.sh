#!/bin/sh
set -eu

EMAILS_FILE="/tmp/oauth2-emails.txt"
echo "${OAUTH_EMAIL:-chris@caldwell.ws}" > "${EMAILS_FILE}"

exec /bin/oauth2-proxy --authenticated-emails-file="${EMAILS_FILE}"
