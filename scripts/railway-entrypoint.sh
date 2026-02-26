#!/bin/bash
set -e

echo "[Railway] Starting Open Notebook on Railway..."

# === Volume Setup ===
# Railway allows one volume per service. We mount it at /data
# and create subdirectories for app data and SurrealDB data.
VOLUME_PATH="${RAILWAY_VOLUME_MOUNT_PATH:-/data}"

echo "[Railway] Setting up data directories under ${VOLUME_PATH}..."
mkdir -p "${VOLUME_PATH}/app_data"
mkdir -p "${VOLUME_PATH}/surreal_data"

# Remove existing directories created during Docker build
rm -rf /app/data /mydata

# Create symlinks so the application finds data where it expects
ln -sf "${VOLUME_PATH}/app_data" /app/data
ln -sf "${VOLUME_PATH}/surreal_data" /mydata

echo "[Railway] Data directories configured:"
echo "  /app/data -> ${VOLUME_PATH}/app_data"
echo "  /mydata -> ${VOLUME_PATH}/surreal_data"

# === Port Configuration ===
# Railway assigns $PORT for the public-facing service.
# The frontend (Next.js) binds to $PORT.
# The API (FastAPI) stays on 5055 internally.
# SurrealDB stays on 8000 internally.
if [ -n "$PORT" ]; then
    echo "[Railway] Railway PORT detected: $PORT"
else
    export PORT=8502
    echo "[Railway] No PORT set, defaulting frontend to 8502"
fi

# === API URL Configuration ===
# If RAILWAY_PUBLIC_DOMAIN is set but API_URL is not,
# automatically configure API_URL to use the Railway domain.
# This prevents the auto-detection from appending :5055.
if [ -z "$API_URL" ] && [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
    export API_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
    echo "[Railway] Auto-configured API_URL=${API_URL}"
fi

# === SurrealDB Configuration ===
export SURREAL_URL="${SURREAL_URL:-ws://localhost:8000/rpc}"
export SURREAL_USER="${SURREAL_USER:-root}"
export SURREAL_PASSWORD="${SURREAL_PASSWORD:-root}"
export SURREAL_NAMESPACE="${SURREAL_NAMESPACE:-open_notebook}"
export SURREAL_DATABASE="${SURREAL_DATABASE:-open_notebook}"

echo "[Railway] Configuration summary:"
echo "  Frontend port: ${PORT}"
echo "  API port: 5055 (internal)"
echo "  SurrealDB: ${SURREAL_URL}"
echo "  API_URL: ${API_URL:-<not set>}"

# Launch supervisord
echo "[Railway] Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
