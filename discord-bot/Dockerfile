FROM python:3.12-slim-bullseye AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

RUN curl -fsSL https://storage.googleapis.com/anthropic-release/claude/latest/install.sh | sh \
    && CLAUDE_PATH=$(find /root -path "*/bin/claude" -type f 2>/dev/null | head -1) \
    && echo "Found claude at: $CLAUDE_PATH" \
    && cp "$CLAUDE_PATH" /usr/local/bin/claude \
    && chmod +x /usr/local/bin/claude

FROM python:3.12-slim-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin/claude /usr/local/bin/claude
COPY --from=builder /root/.claude/ /home/botuser/.claude/

RUN groupadd -g 1000 botuser && useradd -u 1000 -g botuser -m botuser
RUN mkdir -p /data/threads /data/projects && chown -R botuser:botuser /data

WORKDIR /app
COPY . /app

RUN chown -R botuser:botuser /app /home/botuser

USER botuser

CMD ["python3", "bot.py"]
