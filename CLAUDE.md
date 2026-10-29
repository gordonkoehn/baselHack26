# AI-tool conventions (Claude, Copilot, Cursor — all read this)

48h hackathon. Speed over polish, but **main must always be green and demoable**.

## Layout
- `shared/schema.json` — the API contract. **Source of truth.** Examples in `shared/examples/`.
- `backend/` — FastAPI (Python 3.12, uv). Entry `app/main.py`; models in `app/contracts.py`.
- `frontend/` — Next.js + TypeScript + Tailwind. Calls the backend only via `src/lib/api.ts`; types in `src/lib/contracts.ts`.
- `/api/*` on the frontend is proxied to the backend (`next.config.ts`, env `BACKEND_URL`).

## Rules
- Changing a data shape: edit `shared/schema.json` + example FIRST, then `backend/app/contracts.py` and `frontend/src/lib/contracts.ts` in the same PR. Announce it in the team chat.
- All endpoints live under `/api/`.
- Fake anything non-core (in-memory data, hardcoded users, no auth).
- Small PRs, merged within the hour. Don't refactor code you don't own.
- Run `make check` before pushing. Add a smoke test for every new endpoint in `backend/tests/`.
- After adding a Python dependency (`uv add x`), the `requirements.txt` export must be committed (`make check` does it).
- Secrets only in `.env` (gitignored) and Vercel env vars. Never commit keys.
- Next.js here is v16 — read `frontend/AGENTS.md` before using Next APIs you're unsure about.
