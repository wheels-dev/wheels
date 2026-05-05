#!/usr/bin/env bash
# Local Docker-based matrix runner for the Wheels framework test suite.
#
# Mirrors the GitHub Actions compat-matrix.yml workflow exactly so contributors
# can reproduce CI failures locally. Source is bind-mounted via compose.yml
# (./:/wheels-test-suite), so edit-reload-test cycles don't require image
# rebuilds — only the Wheels application is reloaded between iterations.
#
# Usage:
#   tools/test-matrix.sh                       # Lucee 7 + SQLite (happy path)
#   tools/test-matrix.sh lucee7 mysql          # Lucee 7 + MySQL
#   tools/test-matrix.sh lucee7 sqlite,mysql   # Multiple DBs, one engine
#   tools/test-matrix.sh lucee6,lucee7 sqlite  # Multiple engines, one DB
#   tools/test-matrix.sh --all                 # Full matrix (mirrors CI)
#   tools/test-matrix.sh --rebuild lucee7      # Force docker compose build
#   tools/test-matrix.sh --down                # Tear down all containers
#   tools/test-matrix.sh --keep lucee7 sqlite  # Default — leave containers up
#
# Engines (mirrors compat-matrix.yml matrix.cfengine):
#   lucee6, lucee7, adobe2023, adobe2025, boxlang
#
# Databases (mirrors compat-matrix.yml DATABASES env):
#   sqlite, h2 (Lucee only), mysql, postgres, sqlserver, cockroachdb, oracle
#
# Container naming: COMPOSE_PROJECT_NAME=wheels is forced so containers are
# named wheels-<service>-1 (matching CI). Without this, Docker Compose names
# them after the cwd, which breaks scripts that reference `wheels-mysql-1` etc.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# Force CI-equivalent container names (wheels-<service>-1).
export COMPOSE_PROJECT_NAME="wheels"

# Engine → port mapping (mirrors compat-matrix.yml env: PORT_<engine>).
# Using a function instead of an associative array so this works under macOS's
# bundled bash 3.2 (no `declare -A`).
engine_port() {
  case "$1" in
    lucee6)    echo 60006 ;;
    lucee7)    echo 60007 ;;
    adobe2023) echo 62023 ;;
    adobe2025) echo 62025 ;;
    boxlang)   echo 60001 ;;
    *)         echo "" ;;
  esac
}

# Engines and DBs in the CI matrix. Anything outside these lists is rejected
# upfront — keeps "ran locally, broke in CI" surprises down.
ALL_ENGINES="lucee6 lucee7 adobe2023 adobe2025 boxlang"

# Databases that need an external container (vs file-based sqlite/h2).
EXTERNAL_DBS="mysql postgres sqlserver cockroachdb oracle"

# ── Argument parsing ────────────────────────────────────────────────────
REBUILD=false
DOWN_ONLY=false
KEEP_RUNNING=true   # default: leave containers up between runs for fast iteration
ALL=false
ENGINES=""
DATABASES=""

usage() {
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) ALL=true; shift ;;
    --rebuild) REBUILD=true; shift ;;
    --down) DOWN_ONLY=true; shift ;;
    --keep) KEEP_RUNNING=true; shift ;;
    -h|--help) usage 0 ;;
    -*)
      echo "Unknown flag: $1" >&2
      usage 1
      ;;
    *)
      if [[ -z "$ENGINES" ]]; then
        ENGINES="$1"
      elif [[ -z "$DATABASES" ]]; then
        DATABASES="$1"
      else
        echo "Too many positional arguments: $1" >&2
        usage 1
      fi
      shift
      ;;
  esac
done

# ── Tear-down only ──────────────────────────────────────────────────────
if [[ "$DOWN_ONLY" == "true" ]]; then
  echo "Stopping all containers in project '${COMPOSE_PROJECT_NAME}'..."
  docker compose down --remove-orphans
  exit 0
fi

# ── Defaults / matrix expansion ─────────────────────────────────────────
if [[ "$ALL" == "true" ]]; then
  ENGINES="$ALL_ENGINES"
  DATABASES="sqlite,mysql,postgres,sqlserver,cockroachdb,oracle"
fi

ENGINES="${ENGINES:-lucee7}"
DATABASES="${DATABASES:-sqlite}"

# Normalize: replace commas with spaces.
ENGINES="${ENGINES//,/ }"
DATABASES="${DATABASES//,/ }"

# ── Validate inputs ─────────────────────────────────────────────────────
for engine in $ENGINES; do
  if [[ -z "$(engine_port "$engine")" ]]; then
    echo "Unknown engine: $engine" >&2
    echo "Valid engines: $ALL_ENGINES" >&2
    exit 1
  fi
done

VALID_DBS="sqlite h2 mysql postgres sqlserver cockroachdb oracle"
for db in $DATABASES; do
  if ! echo " $VALID_DBS " | grep -q " $db "; then
    echo "Unknown database: $db" >&2
    echo "Valid databases: $VALID_DBS" >&2
    exit 1
  fi
done

# ── Helpers ─────────────────────────────────────────────────────────────
header() {
  printf '\n══════════════════════════════════════════════\n%s\n══════════════════════════════════════════════\n' "$*"
}

wait_for_http() {
  # $1: name (for logging)  $2: url  $3: max attempts
  local name="$1" url="$2" max="${3:-60}"
  local i
  for ((i = 1; i <= max; i++)); do
    if curl -s -o /dev/null --connect-timeout 2 --max-time 5 -w "%{http_code}" "$url" | grep -qE "^(200|302|404|500)$"; then
      echo "  ${name} ready (attempt ${i})"
      return 0
    fi
    sleep 2
  done
  echo "::error::${name} not ready after ${max} attempts" >&2
  return 1
}

# Portable wait loop — replaces GNU coreutils `timeout` (not present on
# macOS by default). Polls `cmd` until it succeeds or `max_seconds` elapse.
wait_for_cmd() {
  # $1: max_seconds  $2: poll_interval  $3+: command (passed to bash -c)
  local max="$1" interval="$2"; shift 2
  local cmd="$*"
  local elapsed=0
  while (( elapsed < max )); do
    if bash -c "$cmd" >/dev/null 2>&1; then
      return 0
    fi
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done
  return 1
}

wait_for_db() {
  # Mirrors compat-matrix.yml "Wait for other databases" step (lines 191-226).
  local db="$1"
  case "$db" in
    sqlite|h2)
      return 0
      ;;
    mysql)
      echo "  Waiting for MySQL..."
      wait_for_cmd 60 2 'docker exec wheels-mysql-1 mysqladmin ping -h localhost -u root -pwheelstestdb --silent' \
        || echo "::warning::MySQL not ready after 60s" >&2
      ;;
    postgres)
      echo "  Waiting for PostgreSQL..."
      wait_for_cmd 60 2 'docker exec wheels-postgres-1 pg_isready -U wheelstestdb' \
        || echo "::warning::PostgreSQL not ready after 60s" >&2
      ;;
    sqlserver)
      echo "  Waiting for SQL Server..."
      wait_for_cmd 120 5 'docker exec wheels-sqlserver-1 /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "x!bsT8t60yo0cTVTPq" -Q "SELECT 1" -C 2>/dev/null | grep -q "1"' \
        || echo "::warning::SQL Server not ready after 120s" >&2
      ;;
    cockroachdb)
      echo "  Waiting for CockroachDB..."
      wait_for_cmd 60 2 'docker exec wheels-cockroachdb-1 cockroach sql --insecure -e "SELECT 1"' \
        || echo "::warning::CockroachDB not ready after 60s" >&2
      echo "  Waiting for CockroachDB init..."
      wait_for_cmd 60 2 '[ "$(docker inspect --format="{{.State.Status}}" wheels-cockroachdb-init-1 2>/dev/null)" = "exited" ]' \
        || echo "::warning::CockroachDB init didn't complete in 60s" >&2
      ;;
    oracle)
      echo "  Waiting for Oracle..."
      wait_for_cmd 300 5 'docker exec wheels-oracle-1 sqlplus -S wheelstestdb/wheelstestdb@localhost:1521/wheelstestdb <<< "SELECT 1 FROM DUAL; EXIT;"' \
        || echo "::warning::Oracle not ready after 300s" >&2
      ;;
  esac
}

start_engine() {
  # $1: engine name
  local engine="$1"
  local port
  port="$(engine_port "$engine")"

  if [[ "$REBUILD" == "true" ]]; then
    echo "Building image for ${engine} (--rebuild)..."
    docker compose build --no-cache "$engine"
  fi

  echo "Starting ${engine}..."
  docker compose up -d "$engine"

  wait_for_http "${engine}" "http://localhost:${port}/" 60 || {
    docker logs "wheels-${engine}-1" 2>&1 | tail -50 >&2
    return 1
  }
}

start_databases() {
  # $@: list of databases
  local needed=()
  for db in "$@"; do
    if echo " $EXTERNAL_DBS " | grep -q " $db "; then
      needed+=("$db")
    fi
  done

  if [[ ${#needed[@]} -eq 0 ]]; then
    return 0
  fi

  # CockroachDB needs the init sidecar.
  local services=("${needed[@]}")
  if printf '%s\n' "${needed[@]}" | grep -q cockroachdb; then
    services+=("cockroachdb-init")
  fi

  echo "Starting external databases: ${needed[*]}"
  docker compose up -d "${services[@]}"

  for db in "${needed[@]}"; do
    wait_for_db "$db"
  done
}

run_tests_for_engine_db() {
  # $1: engine  $2: db  $3: db_index (1-based, for restart logic)
  local engine="$1" db="$2" db_index="$3"
  local port
  port="$(engine_port "$engine")"
  local url="http://localhost:${port}/wheels/core/tests?db=${db}&format=json"

  # Mirrors compat-matrix.yml lines 266-288: restart between DB runs to clear
  # cached model metadata. First run skips the restart.
  if [[ "$db_index" -gt 1 ]]; then
    echo "  Restarting ${engine} for clean app state..."
    docker restart "wheels-${engine}-1" >/dev/null
    wait_for_http "${engine} (restart)" "http://localhost:${port}/" 30 || return 1
  fi

  # Warm-up: trigger onApplicationStart before test run.
  echo "  Warming up Wheels app..."
  curl -s -o /dev/null --max-time 60 "http://localhost:${port}/" || true
  sleep 2

  local result_file="/tmp/wheels-matrix-${engine}-${db}.json"
  echo "  Running tests: ${url}"
  local http_code
  http_code=$(curl -s -o "$result_file" --max-time 900 -w "%{http_code}" "$url" || echo "000")
  echo "  HTTP ${http_code}"

  if [[ "$http_code" != "200" && "$http_code" != "417" ]]; then
    echo "::error::${engine}+${db}: HTTP ${http_code}" >&2
    head -50 "$result_file" 2>/dev/null >&2 || true
    return 1
  fi

  # Parse + display summary (matches tools/ci/run-tests.sh formatting).
  python3 - <<EOF
import json, sys
try:
    d = json.load(open("$result_file"))
except Exception as e:
    print(f"  Could not parse result JSON: {e}")
    sys.exit(2)
p = int(d.get("totalPass", 0))
f = int(d.get("totalFail", 0))
e_ = int(d.get("totalError", 0))
dur = float(d.get("totalDuration", 0)) / 1000
status = "OK" if (f == 0 and e_ == 0) else "FAIL"
color = "\033[32m" if status == "OK" else "\033[31m"
print(f"  {color}{status}\033[0m: {p} passed, {f} failed, {e_} errors ({dur:.1f}s)")
if status == "FAIL":
    for b in d.get("bundleStats", []):
        for s in b.get("suiteStats", []):
            for sp in s.get("specStats", []):
                if sp.get("status") in ("Failed", "Error"):
                    msg = (sp.get("failMessage") or "")[:160]
                    print(f"    {sp['status']}: {sp.get('name', '?')}: {msg}")
    sys.exit(1)
EOF
}

# ── Main ────────────────────────────────────────────────────────────────
header "Local matrix run: engines='${ENGINES}' databases='${DATABASES}'"

# Build the union of databases needed across all selected engines, accounting
# for h2 being Lucee-only (mirrors compat-matrix.yml lines 41-46).
ALL_REQUESTED_DBS=""
for db in $DATABASES; do
  ALL_REQUESTED_DBS="$ALL_REQUESTED_DBS $db"
done

# Start any external DB containers up front. (Same pattern as CI: brings up
# the whole DB set at the start of the engine job.)
start_databases $ALL_REQUESTED_DBS

OVERALL_STATUS=0
# bash 3.2 compatibility: track results in a flat newline-delimited string of
# "engine+db=status" entries instead of an associative array.
RESULTS=""

record_result() {
  RESULTS="${RESULTS}${1}+${2}=${3}"$'\n'
}

lookup_result() {
  echo "$RESULTS" | awk -F'=' -v key="${1}+${2}" '$1==key {print $2; exit}'
}

for engine in $ENGINES; do
  header "Engine: ${engine}"
  if ! start_engine "$engine"; then
    OVERALL_STATUS=1
    for db in $DATABASES; do record_result "$engine" "$db" "engine-down"; done
    continue
  fi

  db_index=0
  for db in $DATABASES; do
    db_index=$((db_index + 1))

    # h2 is Lucee-only (mirrors compat-matrix.yml lines 41-46).
    if [[ "$db" == "h2" && "$engine" != lucee* ]]; then
      echo "  Skipping h2 on ${engine} (Lucee-only)"
      record_result "$engine" "$db" "skip"
      continue
    fi

    if run_tests_for_engine_db "$engine" "$db" "$db_index"; then
      record_result "$engine" "$db" "pass"
    else
      record_result "$engine" "$db" "fail"
      OVERALL_STATUS=1
    fi
  done
done

# ── Summary ─────────────────────────────────────────────────────────────
header "Summary"
printf '%-12s %-12s %s\n' "ENGINE" "DB" "RESULT"
for engine in $ENGINES; do
  for db in $DATABASES; do
    status="$(lookup_result "$engine" "$db")"
    [[ -z "$status" ]] && status="?"
    color="\033[0m"
    case "$status" in
      pass) color="\033[32m" ;;
      fail|engine-down) color="\033[31m" ;;
      skip) color="\033[33m" ;;
    esac
    printf "%-12s %-12s ${color}%s\033[0m\n" "$engine" "$db" "$status"
  done
done

if [[ "$KEEP_RUNNING" == "true" && "$OVERALL_STATUS" == "0" ]]; then
  echo
  echo "Containers left running. Tear down with: tools/test-matrix.sh --down"
fi

exit "$OVERALL_STATUS"
