#!/usr/bin/env bash
# Boots backend + built frontend, checks the frontend's /api proxy reaches the backend.
set -euo pipefail
cd "$(dirname "$0")/.."
(cd backend && uv run uvicorn app.main:app --port 8000 >/tmp/smoke-backend.log 2>&1) &
(cd frontend && npx next start -p 3000 >/tmp/smoke-frontend.log 2>&1) &
trap 'kill $(jobs -p) 2>/dev/null || true' EXIT
for _ in $(seq 30); do curl -sf localhost:3000/api/health >/dev/null && break; sleep 1; done
curl -sf localhost:3000/api/health | grep -q '"ok"'
curl -sf localhost:3000/api/items | grep -q '"title"'
curl -sf localhost:3000/ | grep -q 'baselhack26'
echo "smoke OK"
