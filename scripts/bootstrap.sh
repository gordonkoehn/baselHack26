#!/usr/bin/env bash
# Friday-night one-shot: team repo from template + CI-gated main + Copilot reviews + issue labels + Vercel deploys.
#
#   ./scripts/bootstrap.sh <repo-name> [github-handle ...]
#
# Needs: gh (logged in), vercel CLI (logged in), python3. Vercel GitHub app must have access to the new repo
# (Vercel dashboard → Settings → Git, "All repositories" is easiest).
set -euo pipefail
TEMPLATE="gordonkoehn/baselHack26"
NAME="${1:?usage: bootstrap.sh <repo-name> [github-handle ...]}"; shift
OWNER="$(gh api user -q .login)"
REPO="$OWNER/$NAME"

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

step "1/6 repo $REPO from template"
if gh repo view "$REPO" >/dev/null 2>&1; then echo "exists, reusing"
else gh repo create "$REPO" --public --template "$TEMPLATE" --clone; fi

step "2/6 collaborators: ${*:-none}"
for u in "$@"; do gh api -X PUT "repos/$REPO/collaborators/$u" -f permission=push >/dev/null && echo "invited $u"; done

step "3/6 repo settings: squash-only, auto-delete branches, auto-merge"
gh api -X PATCH "repos/$REPO" -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true -F allow_auto_merge=true >/dev/null

step "4/6 main ruleset: PR + green CI required, no human review, Copilot reviews advisory"
gh api "repos/$REPO/rulesets" -q '.[].name' | grep -qx main-green || gh api -X POST "repos/$REPO/rulesets" --input - >/dev/null <<JSON
{
  "name": "main-green", "target": "branch", "enforcement": "active",
  "conditions": { "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] } },
  "bypass_actors": [ { "actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always" } ],
  "rules": [
    { "type": "non_fast_forward" },
    { "type": "pull_request", "parameters": { "required_approving_review_count": 0, "dismiss_stale_reviews_on_push": false,
      "require_code_owner_review": false, "require_last_push_approval": false, "required_review_thread_resolution": false } },
    { "type": "required_status_checks", "parameters": { "strict_required_status_checks_policy": false,
      "required_status_checks": [ { "context": "ci" } ] } },
    { "type": "copilot_code_review", "parameters": { "review_on_push": true, "review_draft_pull_requests": false } }
  ]
}
JSON
echo "ok (admins can bypass in an emergency)"

step "5/6 issue labels + pinned scope issue"
for l in "frontend:1d76db" "backend:0e8a16" "contract:d93f0b" "blocked:b60205" "demo:fbca04" "todo:ededed" "stretch:c5def5"; do
  gh label create "${l%%:*}" --color "${l##*:}" -R "$REPO" --force >/dev/null
done
if ! gh issue list -R "$REPO" -S "Scope & demo in:title" --json number -q '.[0].number' | grep -q .; then
  url=$(gh issue create -R "$REPO" -t "🎯 Scope & demo script" -l demo -b "$(cat <<'MD'
**One-liner:** 

**Core flow (the demo, 3 steps max):**
1. 
2. 
3. 

**Faked on purpose:** 

**Who owns what:** @… frontend · @… backend · @… story/pitch

**Timeline:** core flow E2E by Sat 13:00 · feature freeze Sat 22:00 · code freeze Sun 11:00
MD
)")
  gh issue pin "$url" -R "$REPO" >/dev/null; echo "pinned $url"
fi

step "6/6 Vercel: two projects (frontend, backend) wired to $REPO"
TOKEN=$(python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/Library/Application Support/com.vercel.cli/auth.json')))['token'])")
vapi() { curl -sS -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' "$@"; }
mkproj() { # name rootDir framework
  vapi -X POST https://api.vercel.com/v11/projects -d "{\"name\":\"$1\",\"rootDirectory\":\"$2\",\"framework\":$3,
    \"gitRepository\":{\"type\":\"github\",\"repo\":\"$REPO\"}}" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('id') or d)"
}
low=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
mkproj "$low-api" backend '"fastapi"'
mkproj "$low-web" frontend '"nextjs"'
BACKEND_URL="https://$low-api.vercel.app"
vapi -X POST "https://api.vercel.com/v10/projects/$low-web/env?upsert=true" \
  -d "{\"key\":\"BACKEND_URL\",\"value\":\"$BACKEND_URL\",\"type\":\"plain\",\"target\":[\"production\",\"preview\",\"development\"]}" >/dev/null
# first deploys: an empty commit to main triggers both projects via git integration
git -C "$NAME" commit --allow-empty -qm "chore: trigger first deploy" 2>/dev/null && git -C "$NAME" push -q 2>/dev/null \
  || gh api -X POST "repos/$REPO/dispatches" -f event_type=noop >/dev/null || true

cat <<DONE

✅ Done.
   Repo:     https://github.com/$REPO
   Frontend: https://$low-web.vercel.app   (deploys on every merge to main, previews on PRs)
   Backend:  $BACKEND_URL/api/health
   Next:     cd $NAME && make setup && make dev
             fill in the pinned 🎯 issue together, then split it into Task issues.
DONE
