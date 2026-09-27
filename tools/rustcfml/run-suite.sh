#!/usr/bin/env bash
# Run the Wheels core suite on the pinned RustCFML engine build and compare the
# outcome against the checked-in known-failure baseline (tools/rustcfml/baseline.json).
#
# RustCFML is a supported JVM-free CFML engine. This script backs both the
# required PR check (.github/workflows/rustcfml-ci.yml) and the release-matrix
# leg (compat-matrix.yml). Pass criteria is "no NEW failures versus the
# baseline", not zero failures — residual engine bugs are tracked in
# tools/rustcfml/baseline.json with upstream issue links in the "_notes" key.
#
# Usage:
#   bash tools/rustcfml/run-suite.sh                  # compare against baseline
#   bash tools/rustcfml/run-suite.sh --write-baseline # regenerate baseline.json
#                                                     # (run after bumping ENGINE_VERSION)
#
# Environment overrides:
#   RUSTCFML_BIN          path to an existing engine binary (skips download)
#   RUSTCFML_PORT         port to serve on (default 8513)
#   RUSTCFML_RESULT_JSON  write a machine-readable verdict here (compare mode)
#
# Exit codes: 0 = no new failures (or baseline written); 3 = the suite ran and
# the engine was REJECTED (new named failures, or fail/error totals above the
# baseline); 1 = the engine could not be evaluated (download, boot, unparseable
# response, missing baseline). Callers that only need pass/fail treat any
# non-zero code as a failure; tools/rustcfml/check-version.sh tells 3 from 1.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$DIR/../.." && pwd)"
# RUSTCFML_VERSION overrides the pinned ENGINE_VERSION so the version-check
# workflow can run the suite against a candidate release before committing a
# bump (tools/rustcfml/check-version.sh).
VERSION="${RUSTCFML_VERSION:-$(tr -d '[:space:]' < "$DIR/ENGINE_VERSION")}"
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
OUT="$(mktemp)"
WHEELS_CI=true "$BIN" --serve "$REPO_ROOT/public" --port "$PORT" > "$SERVE_LOG" 2>&1 &
SERVE_PID=$!
cleanup() {
  kill "$SERVE_PID" 2>/dev/null || true
  rm -f "$SERVE_LOG" "$OUT"
}
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
curl -s --max-time 900 \
  "http://127.0.0.1:$PORT/index.cfm/wheels/core/tests?db=sqlite&format=json" \
  -o "$OUT" || { echo "suite request failed"; exit 1; }

# --- parse + compare -----------------------------------------------------------
python3 - "$OUT" "$BASELINE" "$MODE" "$VERSION" "$REPO_ROOT" <<'PY'
import hashlib, importlib.util, json, os, sys

out_path, baseline_path, mode, version, repo_root = sys.argv[1:6]

# Shared TestBox result walker (also used by the CLI harness): it recurses
# suiteStats at every level, which the old in-line walker did not (#3687).
_spec = importlib.util.spec_from_file_location(
    "testbox_results", os.path.join(repo_root, "tools", "ci", "testbox_results.py"))
tbr = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(tbr)

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

failures = tbr.walk(data)
failing = {}
for f in failures:
    # Keys are committed in baseline.json: "<bundle> :: <suite> > <nested> :: <spec>",
    # or "<bundle> :: (bundle-level exception)". Keep the shape stable.
    if f["kind"] == "BundleError":
        key = f"{f['bundle']} :: (bundle-level exception)"
    else:
        key = f"{f['bundle']} :: {f['path_text']} :: {f['name']}"
    failing[key] = {
        "status": f["status"] or "?",
        "message": f["message"].replace("\n", " | "),
        "detail": f["detail"].replace("\n", " | "),
    }
# Diagnostic only: when the walk and TestBox's own totals disagree, say so.
# The totals backstop below still gates on the numbers.
walk_mismatch = tbr.reconcile(data, failures)

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
        "failing": sorted(failing.keys()),
    }
    # Preserve the human-maintained "_notes" (upstream issue links) across
    # regenerations.
    try:
        existing = json.load(open(baseline_path))
        if isinstance(existing.get("_notes"), list):
            payload["_notes"] = existing["_notes"]
    except Exception:
        pass
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
new = sorted(failing.keys() - known)
fixed = sorted(known - failing.keys())

# Coarse totals backstop: the failing[] walk only sees per-spec entries and
# bundle-level exceptions, so a regression surfacing through a response shape
# the walk doesn't reach (lifecycle/suite-level errors) could raise the totals
# without adding a named entry. Flag totalFail/totalError rising above baseline
# even when the named diff is empty.
base_totals = baseline.get("totals", {})
totals_worse = [
    f"{key}: {int(base_totals.get(key, 0))} -> {totals[key]}"
    for key in ("totalFail", "totalError")
    if totals[key] > int(base_totals.get(key, 0))
]

summary_lines = []
if fixed:
    summary_lines.append(f"NEWLY PASSING vs baseline ({len(fixed)}):")
    summary_lines += [f"  + {item}" for item in fixed]
    summary_lines.append("  (baseline can be refreshed with --write-baseline)")
if failing:
    known_now = sorted(failing.keys())
    summary_lines.append(f"FAILING SPECS (all {len(known_now)}):")
    for item in known_now:
        summary_lines.append(f"  * {item}")
        info = failing.get(item, {})
        msg = info.get("message", "")
        if msg:
            summary_lines.append(f"      [{info.get('status', '?')}] {msg[:400]}")
if new:
    summary_lines.append(f"NEW FAILURES vs baseline ({len(new)}):")
    for item in new:
        summary_lines.append(f"  - {item}")
        info = failing.get(item, {})
        msg = info.get("message", "")
        if msg:
            summary_lines.append(f"      [{info.get('status', '?')}] {msg[:400]}")
        detail = info.get("detail", "")
        if detail and detail != msg:
            summary_lines.append(f"      detail: {detail[:400]}")
if totals_worse:
    summary_lines.append("TOTALS REGRESSION vs baseline (no named entry — check response shape):")
    summary_lines += [f"  - {item}" for item in totals_worse]
if walk_mismatch:
    summary_lines.append("WALK/TOTALS MISMATCH (the named list may be incomplete):")
    summary_lines += [f"  - {item}" for item in walk_mismatch]
for line in summary_lines:
    print(line)

rejected = bool(new or totals_worse)
result_path = os.environ.get("RUSTCFML_RESULT_JSON")
if result_path:
    # The fingerprint identifies "this candidate, failing this way", so a
    # daily re-check of an already-rejected candidate can stay quiet (#3687).
    fingerprint = hashlib.sha256(
        (version + "\n" + "\n".join(new) + "\n" + "\n".join(totals_worse)).encode("utf-8")
    ).hexdigest()[:16]
    with open(result_path, "w") as fh:
        json.dump({
            "engineVersion": version,
            "baselineVersion": baseline.get("engineVersion", "?"),
            "verdict": "rejected" if rejected else "accepted",
            "fingerprint": fingerprint,
            "totals": totals,
            "baselineTotals": base_totals,
            "new": [dict(key=k, **failing[k]) for k in new],
            "newlyPassing": fixed,
            "totalsWorse": totals_worse,
            "walkMismatch": walk_mismatch,
        }, fh, indent=2)
        fh.write("\n")

step_summary = os.environ.get("GITHUB_STEP_SUMMARY")
if step_summary:
    with open(step_summary, "a") as fh:
        fh.write(f"## RustCFML {version} (experimental lane)\n\n")
        fh.write(f"{totals['totalPass']} pass / {totals['totalFail']} fail / "
                 f"{totals['totalError']} error / {totals['totalSkipped']} skipped — "
                 f"baseline {baseline.get('engineVersion', '?')}\n\n")
        for line in summary_lines:
            fh.write(line + "\n")
        if not new and not totals_worse:
            fh.write("\nNo new failures versus baseline.\n")

sys.exit(3 if rejected else 0)
PY
