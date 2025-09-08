# syntax=docker/dockerfile:1.7
FROM python:3.12-slim

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

# System deps (keep minimal; add others only if you really need them)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl build-essential gcc \
 && rm -rf /var/lib/apt/lists/*

 
# Install deps first (leverages Docker layer cache)
COPY requirements.txt .
RUN python -m pip install --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt
 
# Copy app source
COPY . .

# Run as non-root for security
RUN useradd -ms /bin/bash appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8598

# Streamlit exposes a health path on /_stcore/health
HEALTHCHECK --interval=30s --timeout=3s --start-period=45s --retries=5 \
  CMD curl --fail http://localhost:8598/_stcore/health || exit 1

ENTRYPOINT ["streamlit", "run", "streamlit_app.py", "--server.port=8598", "--server.address=0.0.0.0"]
