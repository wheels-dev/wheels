#!/usr/bin/env bash
# Regression check: TestClient works behind an AJP front end (#4210).
#
# Runs the internal TestClient specs THROUGH httpd -> mod_proxy_ajp -> Lucee's AJP connector,
# with httpd sharing Lucee's network namespace like IIS+BonCode or mod_jk on the app server.
# Measured (2026-10): behind mod_proxy_ajp, both Runwar/Undertow and Tomcat AJP report the
# front end's port as the servlet's local port, so the request looks unmapped and the base URL
# comes from cgi detection (Host: localhost, reaching httpd over loopback). IIS+BonCode speaks
# the same AJP13 protocol but has not been measured.
#
# Usage: bash tools/ci/ajp/run.sh [project-name]
#   AJP_HTTPD_PORT  host port for httpd (default 9590)
#   AJP_KEEP=1      leave the containers running
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PROJECT="${1:-wheels-ajp}"
PORT="${AJP_HTTPD_PORT:-9590}"
OUT="${AJP_RESULT_JSON:-$(mktemp)}"
dc() { docker compose -p "$PROJECT" --project-directory "$ROOT" -f "$ROOT/compose.yml" -f "$ROOT/tools/ci/ajp/compose.ajp.yml" "$@"; }
cleanup() { [ "${AJP_KEEP:-0}" = 1 ] || dc down -v >/dev/null 2>&1; }
trap cleanup EXIT

if ! up_log=$(dc up -d lucee7 httpd 2>&1); then
  echo "compose up failed:"; echo "$up_log" | tail -5; exit 1
fi
echo "waiting for Lucee through httpd/AJP on :$PORT ..."
ready=0
for _ in $(seq 1 120); do
  code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' -H 'Host: localhost' "http://127.0.0.1:$PORT/" || true)
  if [ "$code" = 200 ] || [ "$code" = 302 ] || [ "$code" = 404 ]; then
    ready=1
    break
  fi
  sleep 5
done
if [ "$ready" != 1 ]; then
  echo "::error::front end never answered through httpd/AJP on :$PORT (last HTTP code: ${code:-none})"
  dc logs --tail 20 lucee7 httpd 2>&1 | tail -40
  exit 1
fi
echo "front end answered: $code"

curl -s -m 1800 -H 'Host: localhost' \
  "http://127.0.0.1:$PORT/wheels/core/tests?db=sqlite&format=json&reload=true&directory=wheels.tests.specs.internal" \
  -o "$OUT" || { echo "suite request through httpd failed"; exit 1; }

python3 - "$OUT" <<'PY'
import json, sys
raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
try:
    d = json.loads(raw, strict=False)
except Exception:
    print("UNPARSEABLE:", raw[:300]); sys.exit(1)
if "totalPass" not in d:
    print("NO RESULTS:", str(d.get("Message"))[:300]); sys.exit(1)
fails = []
def walk(s, path):
    for sp in s.get("specStats", []):
        if sp["status"] in ("Failed", "Error"):
            fails.append(f"{sp['status']} {path} > {sp['name']} | {(sp.get('failMessage') or '')[:200]}")
    for c in s.get("suiteStats", []):
        walk(c, path + " > " + c["name"])
ran = 0
for b in d.get("bundleStats", []):
    if "testClientSpec" in b.get("path", ""):
        ran += int(float(b.get("totalPass", 0))) + int(float(b.get("totalFail", 0))) + int(float(b.get("totalError", 0)))
    for s in b.get("suiteStats", []):
        walk(s, b.get("path", ""))
print(f"bundles {d.get('bundlesDiscovered')} pass {int(float(d['totalPass']))} fail {d['totalFail']} error {int(float(d['totalError']))}; testClientSpec specs run: {ran}")
for f in fails: print("  ", f)
sys.exit(0 if not fails and ran > 0 else 1)
PY
