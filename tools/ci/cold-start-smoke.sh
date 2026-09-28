#!/usr/bin/env bash
# Cold-first-request smoke (issue #3735, regression net for #3730).
#
# Some engine bugs fire only on the FIRST request a JVM serves, once per JVM.
# On Adobe CF 2023/2025 every cold start returned HTTP 500 from
# onApplicationStart (EmptyStackException in NeoPageContext.popSuperScope, see
# CLAUDE.md invariant 21). Any earlier request absorbs the failure: a Docker
# healthcheck, an HTTP readiness poll, a warm-up call. So this script never
# sends HTTP until the probe it means to assert:
#
#   phase 1 (fresh container, fresh engine home):
#     wait for the port to LISTEN inside the container (read from
#     /proc/net/tcp, which opens no connection at all), then for CommandBox's
#     "Server is up" console line, then
#       request 1: GET /  -> 200 + welcome page, no error template
#       request 2: GET /  -> same (the app must stay up after its first start)
#   phase 2 (plain `docker compose restart`, the engine home is reused):
#     same wait, then
#       request 1: GET /wheels/core/tests?db=sqlite&directory=wheels.tests.specs.global
#                  -> 200, JSON with passes and 0 failures / 0 errors
#       request 2: GET /  -> 200 + welcome page
#
# #3730 failed in both phases, so each phase must pass on its own.
#
# Precondition (the workflow sets it up): the service was started with
#   docker compose up -d <service>
# and its healthcheck disabled through a compose override on COMPOSE_FILE. The
# script refuses to run if the container still has an active healthcheck.
#
#   COMPOSE_FILE=compose.yml:/tmp/cold-start.override.yml \
#     bash tools/ci/cold-start-smoke.sh adobe2023 62023
#
# Exit 0 = every probe passed. Response bodies and headers are kept in
# $SMOKE_OUT_DIR (default ./cold-start-artifacts) for the failure upload.
set -u

SERVICE="${1:?usage: cold-start-smoke.sh <compose-service> <port>}"
PORT="${2:?usage: cold-start-smoke.sh <compose-service> <port>}"
CONTAINER="wheels-${SERVICE}-1"
BASE_URL="http://localhost:${PORT}"
OUT_DIR="${SMOKE_OUT_DIR:-cold-start-artifacts}"
# Seconds to wait for the port to LISTEN. Adobe's first boot installs the engine
# and its cfpm packages into the empty engine home; compat-matrix measured
# ~4-10 min for that, so allow 20.
LISTEN_TIMEOUT="${SMOKE_LISTEN_TIMEOUT:-1200}"
# Per-request ceiling. The first request compiles the framework.
REQUEST_TIMEOUT="${SMOKE_REQUEST_TIMEOUT:-300}"
FAILURES=0

mkdir -p "$OUT_DIR"

# Markers of a failed request: the #3730 exception, the Wheels "failed to
# initialize" fallback body, the Wheels error page, Adobe's error template.
# Checked on HTML responses only; the suite probe is judged by its JSON counts.
ERROR_MARKERS='EmptyStackException|popSuperScope|Wheels failed to initialize|<title>Wheels - Error</title>|Error Occurred While Processing Request'
# The development-mode root route renders vendor/wheels/public/views/congratulations.cfm.
ROOT_MARKER='Welcome to Wheels'
TESTS_PATH='/wheels/core/tests?db=sqlite&directory=wheels.tests.specs.global&format=json'

log() { echo "[cold-start:${SERVICE}] $*"; }

container_status() {
	docker inspect --format '{{.State.Status}}' "$CONTAINER" 2>/dev/null || echo "missing"
}

# Count of CommandBox "Server is up" lines in the container console so far.
server_up_count() {
	docker logs "$CONTAINER" 2>&1 | grep -ac 'Server is up' || true
}

# True when something in the container LISTENs on $PORT. Reads the kernel
# socket tables; it opens no connection, so no request can reach the engine.
# (A TCP connect from the host would not prove anything either: docker-proxy
# accepts on the published port before the engine binds.)
port_listening() {
	local hexport
	hexport=$(printf '%04X' "$PORT")
	docker exec "$CONTAINER" sh -c 'cat /proc/net/tcp /proc/net/tcp6 2>/dev/null' 2>/dev/null |
		awk -v p=":${hexport}" '{ if (substr($2, length($2) - 4) == p && $4 == "0A") found = 1 } END { exit !found }'
}

assert_no_healthcheck() {
	local hc
	hc=$(docker inspect --format '{{json .Config.Healthcheck}}' "$CONTAINER" 2>/dev/null || echo "?")
	case "$hc" in
		null|'{"Test":["NONE"]}') log "healthcheck disabled ($hc)";;
		*)
			echo "::error::${CONTAINER} has an active healthcheck ($hc). It would send the first request and hide a cold-start failure. Start it with the healthcheck disabled."
			exit 1;;
	esac
}

# wait_ready <phase> <server-up lines seen before this start>
wait_ready() {
	local phase="$1" up_before="$2" waited=0 restarts=0 status
	log "$phase: waiting for port $PORT to LISTEN (no HTTP)"
	while ! port_listening; do
		status=$(container_status)
		if [ "$status" = "exited" ] || [ "$status" = "dead" ] || [ "$status" = "missing" ]; then
			# A container that dies during boot never served a request, so a
			# restart still gives a cold first request.
			restarts=$((restarts + 1))
			if [ "$restarts" -gt 2 ]; then
				echo "::error::${CONTAINER} kept exiting during $phase boot (status $status)"
				docker logs "$CONTAINER" 2>&1 | tail -150
				exit 1
			fi
			log "container status '$status', starting it again ($restarts/2)"
			up_before=$(server_up_count)
			docker compose up -d "$SERVICE"
		fi
		if [ "$waited" -ge "$LISTEN_TIMEOUT" ]; then
			echo "::error::${SERVICE} did not LISTEN on $PORT within ${LISTEN_TIMEOUT}s ($phase)"
			docker logs "$CONTAINER" 2>&1 | tail -150
			exit 1
		fi
		sleep 5
		waited=$((waited + 5))
		if [ $((waited % 60)) -eq 0 ]; then log "  still waiting (${waited}s, container=$(container_status))"; fi
	done
	log "$phase: port $PORT is listening after ~${waited}s"

	# CommandBox prints "Server is up" once the engine is serving. The #3730
	# reproduction waited for this line; wait for it too, but do not fail the
	# smoke on a console-format change: LISTEN already means the engine bound.
	local up_waited=0
	while [ "$(server_up_count)" -le "$up_before" ]; do
		if [ "$up_waited" -ge 180 ]; then
			echo "::warning::no new 'Server is up' console line after ${up_waited}s; probing on LISTEN alone"
			break
		fi
		sleep 5
		up_waited=$((up_waited + 5))
	done
	sleep 3
}

# probe <label> <path> <kind: root|tests>
probe() {
	local label="$1" path="$2" kind="$3"
	local body="$OUT_DIR/${label}.body" headers="$OUT_DIR/${label}.headers" status ok=1 why=""
	status=$(curl -sS -D "$headers" -o "$body" -w '%{http_code}' --connect-timeout 10 --max-time "$REQUEST_TIMEOUT" "${BASE_URL}${path}" 2>"$OUT_DIR/${label}.curl-stderr")
	status=${status:-000}

	if [ "$status" != "200" ]; then ok=0; why="status $status"; fi
	if [ "$kind" = "root" ] && grep -aqE "$ERROR_MARKERS" "$body" 2>/dev/null; then
		ok=0
		why="${why:+$why; }error marker '$(grep -aoE "$ERROR_MARKERS" "$body" | head -1)'"
	fi
	if [ "$kind" = "root" ] && ! grep -aqF "$ROOT_MARKER" "$body" 2>/dev/null; then
		ok=0
		why="${why:+$why; }missing '$ROOT_MARKER'"
	fi
	if [ "$kind" = "tests" ]; then
		local counts
		counts=$(python3 - "$body" <<'PY' 2>&1
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8", errors="replace"))
except Exception as e:
    print("unparseable JSON: %s" % e)
    sys.exit(1)
p, f, e = d.get("totalPass", 0), d.get("totalFail", 0), d.get("totalError", 0)
print("pass=%s fail=%s error=%s bundles=%s" % (p, f, e, d.get("bundlesDiscovered", d.get("totalBundles", "?"))))
sys.exit(0 if (p > 0 and f == 0 and e == 0) else 1)
PY
		) || { ok=0; why="${why:+$why; }suite: $counts"; }
		log "  $label suite result: $counts"
	fi

	if [ "$ok" = "1" ]; then
		log "PASS $label: GET $path -> $status"
	else
		echo "::error::cold-start probe $label failed on ${SERVICE}: GET $path -> $why"
		echo "  body head: $(head -c 400 "$body" 2>/dev/null | tr '\n' ' ')"
		FAILURES=$((FAILURES + 1))
	fi
}

assert_no_healthcheck

# Phase 1: the container was just created by `docker compose up -d`.
wait_ready "phase 1 (fresh start)" 0
probe "p1-first-root" "/" root
probe "p1-second-root" "/" root

# Phase 2: plain restart, new JVM, engine home and compiled classes reused.
UP_BEFORE=$(server_up_count)
log "phase 2: docker compose restart $SERVICE"
docker compose restart "$SERVICE"
assert_no_healthcheck
wait_ready "phase 2 (restart)" "$UP_BEFORE"
probe "p2-first-tests" "$TESTS_PATH" tests
probe "p2-second-root" "/" root

if [ "$FAILURES" -gt 0 ]; then
	log "$FAILURES probe(s) failed"
	exit 1
fi
log "all cold-start probes passed"
