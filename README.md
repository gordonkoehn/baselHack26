# baselhack26

Monorepo: `frontend/` (Next.js) + `backend/` (FastAPI) + `shared/` (API contract).

## Run it
Needs Node 20+, [uv](https://docs.astral.sh/uv/), make.

```bash
make setup   # install
make dev     # backend :8000 + frontend :3000 → open http://localhost:3000
make check   # what CI runs — do this before pushing
```

API docs while running: http://localhost:8000/docs

## How we work
- **Contract first:** agree on `shared/schema.json`, then build front and back in parallel against it.
- **No blocking reviews.** Branch → PR → merge within the hour once CI is green. Copilot reviews are advisory.
- **CI is the gatekeeper:** lint, tests, build, full-stack smoke test.
- **Every merge to main deploys** to Vercel (frontend + backend projects). PRs get preview URLs.
- AI tools: conventions in [`CLAUDE.md`](CLAUDE.md).

## Deployment
Two Vercel projects from this repo: root `frontend` and root `backend`. Frontend env `BACKEND_URL` = backend production URL.
