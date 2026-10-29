.PHONY: setup dev backend frontend check smoke

setup:            ## install everything
	cd backend && uv sync
	cd frontend && npm ci

dev:              ## run backend :8000 + frontend :3000 together
	$(MAKE) -j2 backend frontend

backend:
	cd backend && uv run uvicorn app.main:app --reload --port 8000

frontend:
	cd frontend && npm run dev

check:            ## what CI runs — run before pushing
	cd backend && uv run ruff check . && uv run ruff format --check . && uv run pytest -q
	cd backend && uv export --no-dev --no-hashes -q -o requirements.txt && git diff --exit-code requirements.txt
	cd frontend && npm run lint && npm run typecheck && npm run build

smoke:            ## full stack: prod frontend build -> proxy -> backend
	./scripts/smoke.sh
