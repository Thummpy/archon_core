FROM python:3.12-slim-bullseye AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g @anthropic-ai/claude-code

FROM python:3.12-slim-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/bin/node /usr/bin/node
COPY --from=builder /usr/lib/node_modules /usr/lib/node_modules
RUN ln -s /usr/lib/node_modules/.bin/claude /usr/local/bin/claude

RUN groupadd -g 1000 botuser && useradd -u 1000 -g botuser -m botuser
RUN mkdir -p /home/botuser/.claude /data/threads /data/projects && chown -R botuser:botuser /data

WORKDIR /app
COPY . /app

RUN chown -R botuser:botuser /app /home/botuser

USER botuser

CMD ["python3", "bot.py"]
