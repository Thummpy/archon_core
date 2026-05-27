FROM python:3.12-slim-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt \
    && npm install -g @anthropic-ai/claude-code

RUN groupadd -g 1000 botuser && useradd -u 1000 -g botuser -m botuser
RUN mkdir -p /home/botuser/.claude /data/threads /data/projects && chown -R botuser:botuser /data

WORKDIR /app
COPY . /app

RUN chown -R botuser:botuser /app /home/botuser

USER botuser

CMD ["python3", "bot.py"]
