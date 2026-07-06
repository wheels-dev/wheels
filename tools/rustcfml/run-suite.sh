#!/usr/bin/env bash
# Run the Wheels core suite on the pinned RustCFML engine build and compare the
# outcome against the checked-in known-failure baseline (tools/rustcfml/baseline.json).
#
# RustCFML is a JVM-free CFML engine under active development. This lane is
# informational: it is never a merge gate. Pass criteria is "no NEW failures
# versus the baseline", not zero failures — a set of known residual errors
# (no-JVM limitations and open upstream engine issues) is expected and tracked
# in the baseline file.
#
# Usage:
#   bash tools/rustcfml/run-suite.sh                  # compare against baseline
#   bash tools/rustcfml/run-suite.sh --write-baseline # regenerate baseline.json
#                                                     # (run after bumping ENGINE_VERSION)
#
# Environment overrides:
#   RUSTCFML_BIN   path to an existing engine binary (skips download)
#   RUSTCFML_PORT  port to serve on (default 8513)
#
# Exit codes: 0 = no new failures (or baseline written); 1 = boot break, new
# failures, or infrastructure error.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DIR/../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$DIR/ENGINE_VERSION")"
BASELINE="$DIR/baseline.json"
PORT="${RUSTCFML_PORT:-8513}"
MODE="compare"
[ "${1:-}" = "--write-baseline" ] && MODE="write"

# --- resolve engine binary (download once, cache by version) ------------------
case "$(uname -s)-$(uname -m)" in
  Linux-x86_64)   ASSET="rustcfml-linux-x86_64" ;;
  Linux-aarch64)  ASSET="rustcfml-linux-aarch64" ;;
  Darwin-arm64)   ASSET="rustcfml-macos-aarch64" ;;
  Darwin-x86_64)  ASSET="rustcfml-macos-x86_64" ;;
  *) echo "unsupported platform: $(uname -s)-$(uname -m)"; exit 1 ;;
esac

BIN="${RUSTCFML_BIN:-}"
if [ -z "$BIN" ]; then
  CACHE_DIR="${RUSTCFML_CACHE_DIR:-$HOME/.cache/wheels-rustcfml}"
  mkdir -p "$CACHE_DIR"
  BIN="$CACHE_DIR/rustcfml-$VERSION"
  if [ ! -x "$BIN" ]; then
    echo "Downloading RustCFML $VERSION ($ASSET)..."
    gh release download "$VERSION" --repo RustCFML/RustCFML --pattern "$ASSET" --output "$BIN"
    chmod +x "$BIN"
  fi
fi
echo "Engine: $BIN"

# --- serve the repo webroot ----------------------------------------------------
SERVE_LOG="$(mktemp)"
WHEELS_CI=true "$BIN" --serve "$REPO_ROOT/public" --port "$PORT" > "$SERVE_LOG" 2>&1 &
SERVE_PID=$!
cleanup() { kill "$SERVE_PID" 2>/dev/null || true; }
trap cleanup EXIT

UP=0
for _ in $(seq 1 30); do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 1 "http://127.0.0.1:$PORT/" 2>/dev/null || true)
  if [ "$CODE" != "000" ] && [ -n "$CODE" ]; then UP=1; break; fi
  sleep 1
done
if [ "$UP" != 1 ]; then
  echo "ENGINE DID NOT START — serve log tail:"; tail -20 "$SERVE_LOG"; exit 1
fi

# Warm boot, then run the suite. The /index.cfm/ prefix works around RustCFML
# issue #194 (path-info routing without the prefix 404s under urlrewrite).
curl -s -o /dev/null --max-time 120 "http://127.0.0.1:$PORT/index.cfm/" || true
OUT="$(mktemp)"
curl -s --max-time 900 \
  "http://127.0.0.1:$PORT/index.cfm/wheels/core/tests?db=sqlite&format=json" \
  -o "$OUT" || { echo "suite request failed"; exit 1; }

# --- parse + compare -----------------------------------------------------------
python3 - "$OUT" "$BASELINE" "$MODE" "$VERSION" <<'PY'
import json, os, sys

out_path, baseline_path, mode, version = sys.argv[1:5]

raw = open(out_path, encoding="utf-8", errors="replace").read().lstrip()
try:
    # The suite response can carry stray trailing bytes — tolerate them.
    data, _ = json.JSONDecoder().raw_decode(raw)
except Exception as exc:
    print(f"BOOT BREAK: suite returned unparseable output ({exc}); first 400 bytes:")
    print(raw[:400])
    sys.exit(1)

totals = {k: int(data.get(k, 0)) for k in
          ("totalSpecs", "totalPass", "totalFail", "totalError", "totalSkipped")}

failing = set()
def walk(node, bundle, path):
    for spec in node.get("specStats", []):
        if spec.get("status") not in ("Passed", "Skipped"):
            failing.add(f"{bundle} :: {path} :: {spec.get('name', '?')}")
    for nested in node.get("nestedSuiteStats", []) or []:
        walk(nested, bundle, f"{path} > {nested.get('name', '?')}")

for b in data.get("bundleStats", []):
    name = b.get("name", "?")
    ge = b.get("globalException") or {}
    if isinstance(ge, dict) and ge.get("message"):
        failing.add(f"{name} :: (bundle-level exception)")
    for su in b.get("suiteStats", []):
        walk(su, name, su.get("name", "?"))

print(f"RustCFML {version}: {totals['totalPass']} pass, {totals['totalFail']} fail, "
      f"{totals['totalError']} error, {totals['totalSkipped']} skipped "
      f"({len(failing)} distinct failing entries)")

if totals["totalPass"] == 0:
    print("BOOT BREAK: zero passing specs — the engine could not run the suite.")
    print("Response head (the suite likely returned an error payload):")
    print(raw[:600])
    sys.exit(1)

if mode == "write":
    payload = {
        "engineVersion": version,
        "totals": totals,
        "failing": sorted(failing),
    }
    with open(baseline_path, "w") as fh:
        json.dump(payload, fh, indent=2)
        fh.write("\n")
    print(f"Baseline written to {baseline_path} ({len(failing)} known-failing entries).")
    sys.exit(0)

try:
    baseline = json.load(open(baseline_path))
except Exception:
    print(f"No readable baseline at {baseline_path} — run with --write-baseline first.")
    sys.exit(1)

known = set(baseline.get("failing", []))
new = sorted(failing - known)
fixed = sorted(known - failing)

summary_lines = []
if fixed:
    summary_lines.append(f"NEWLY PASSING vs baseline ({len(fixed)}):")
    summary_lines += [f"  + {item}" for item in fixed]
    summary_lines.append("  (baseline can be refreshed with --write-baseline)")
if new:
    summary_lines.append(f"NEW FAILURES vs baseline ({len(new)}):")
    summary_lines += [f"  - {item}" for item in new]
for line in summary_lines:
    print(line)

step_summary = os.environ.get("GITHUB_STEP_SUMMARY")
if step_summary:
    with open(step_summary, "a") as fh:
        fh.write(f"## RustCFML {version} (experimental lane)\n\n")
        fh.write(f"{totals['totalPass']} pass / {totals['totalFail']} fail / "
                 f"{totals['totalError']} error / {totals['totalSkipped']} skipped — "
                 f"baseline {baseline.get('engineVersion', '?')}\n\n")
        for line in summary_lines:
            fh.write(line + "\n")
        if not new:
            fh.write("\nNo new failures versus baseline.\n")

sys.exit(1 if new else 0)
PY
