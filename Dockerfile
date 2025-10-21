# syntax=docker/dockerfile:1.7
FROM python:3.12-slim AS base

LABEL org.opencontainers.image.title="calendar-task-synchronization" \
      org.opencontainers.image.description="Synchronizes OpenProject tasks with Google Calendar" \
      org.opencontainers.image.source="https://github.com/${GITHUB_REPOSITORY}" \
      org.opencontainers.image.revision="${GITHUB_SHA}" \
      org.opencontainers.image.licenses="MIT"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    STREAMLIT_SERVER_HEADLESS=true \
    STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

WORKDIR /app

# Minimal system deps; add only if needed by requirements.txt
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl build-essential gcc tzdata \
 && rm -rf /var/lib/apt/lists/*

# Leverage layer cache for Python deps
COPY requirements.txt .
RUN python -m pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# App source
COPY . .
RUN useradd -ms /bin/bash appuser \
 && mkdir -p /app/config_files/keys \
 && chown -R appuser:appuser /app

# ----- STREAMLIT STAGE -----
FROM base AS streamlit
USER appuser
EXPOSE 8598

# Streamlit exposes a health path on /_stcore/health
HEALTHCHECK --interval=30s --timeout=3s --start-period=45s --retries=5 \
  CMD curl --fail http://localhost:8598/_stcore/health || exit 1

ENTRYPOINT ["streamlit", "run", "streamlit_app.py", "--server.port=8598", "--server.address=0.0.0.0"]

# ----- SCHEDULER (CRON) STAGE -----
FROM base AS scheduler
USER root

# Install cron only in the scheduler image
RUN apt-get update && apt-get install -y --no-install-recommends cron \
 && rm -rf /var/lib/apt/lists/*

# Script that runs the synchronization for all configs
RUN printf '%s\n' '#!/bin/bash' \
  'set -Eeuo pipefail' \
  'shopt -s nullglob' \
  'for ini in /app/config_files/*.ini; do' \
  '  echo "$(date -Is) [sync] Running $ini"' \
  '  /usr/local/bin/python /app/main.py "$ini"' \
  'done' > /usr/local/bin/run_sync.sh \
 && chmod +x /usr/local/bin/run_sync.sh

# Entrypoint that sets TZ, installs the crontab from $SYNC_CRON, and runs cron in foreground
RUN printf '%s\n' '#!/bin/bash' \
  'set -Eeuo pipefail' \
  ': "${SYNC_CRON:=*/20 * * * *}"' \
  ': "${TZ:=Etc/UTC}"' \
  'if [ -f "/usr/share/zoneinfo/$TZ" ]; then ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone; fi' \
  'echo "$SYNC_CRON /usr/local/bin/run_sync.sh >> /proc/1/fd/1 2>&1" > /etc/cron.d/app-cron' \
  'chmod 0644 /etc/cron.d/app-cron' \
  'crontab /etc/cron.d/app-cron' \
  'exec cron -f' > /usr/local/bin/start-scheduler.sh \
 && chmod +x /usr/local/bin/start-scheduler.sh

HEALTHCHECK --interval=60s --timeout=10s --retries=3 CMD pgrep -x cron >/dev/null || exit 1
CMD ["/usr/local/bin/start-scheduler.sh"]
