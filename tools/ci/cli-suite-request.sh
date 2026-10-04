#!/usr/bin/env bash
# cli-suite-request.sh <suite-url> <result-file> <server-log> <port> [max-time]
#
# Runs the CLI module suite request (/wheels/cli/tests) with a per-bundle
# watchdog, and prints the HTTP status on stdout (000 when it didn't finish).
# Used by tools/test-cli-local.sh and tools/ci/run-tests.sh (#4232).
#
# The suite is one request. With progress=1 (added here), the runner view
# (vendor/wheels/public/views/clitests.cfm) prints a "[cli-suite]" line to the
# server's stdout as each bundle starts and ends, and per spec. A stall would
# otherwise show only as the request timeout, which Lucee raises in whatever
# spec next touches a file, not in the one that stalled. When a bundle runs
# longer than WHEELS_CLI_BUNDLE_TIMEOUT seconds (default 120), this names the
# bundle and its last spec, asks the server JVM for a thread dump (SIGQUIT
# prints one to the server's stdout), shows the threads running CFML and the
# full dump, stops the request and exits 3. A request that ends early for
# another reason (e.g. the request timeout) reports the bundle that was running.
set -euo pipefail

url="$1"; result_file="$2"; server_log="$3"; port="$4"; max_time="${5:-600}"
bundle_timeout="${WHEELS_CLI_BUNDLE_TIMEOUT:-120}"
case "$url" in *\?*) url="${url}&progress=1" ;; *) url="${url}?progress=1" ;; esac

from=$(( $(wc -l < "$server_log" 2>/dev/null || echo 0) + 1 ))
progress() { tail -n +"$from" "$server_log" 2>/dev/null | { grep -a '^\[cli-suite\] [0-9]* ' || true; }; }
last_bundle_event() { progress | { grep -a -E '^\[cli-suite\] [0-9]+ (start|end) ' || true; } | tail -1; }
last_spec() { progress | { grep -a ' spec ' || true; } | tail -1 | cut -d' ' -f4-; }

code_file="$(mktemp)"
trap 'rm -f "$code_file"' EXIT
# curl itself in the background (not a subshell), so the watchdog's kill reaches
# it. On a failed or killed transfer --write-out still writes 000.
curl -s -o "$result_file" --max-time "$max_time" --write-out "%{http_code}" "$url" > "$code_file" 2>/dev/null &
curl_pid=$!

stalled=""
while kill -0 "$curl_pid" 2>/dev/null; do
  sleep 5
  last="$(last_bundle_event)"
  case "$last" in
    *" start "*)
      started_ms="$(echo "$last" | awk '{print $2}')"
      if [ $(( $(date +%s) - started_ms / 1000 )) -gt "$bundle_timeout" ]; then
        stalled="$(echo "$last" | awk '{print $4}')"
        break
      fi
      ;;
  esac
done

if [ -n "$stalled" ]; then
  {
    echo "::error::CLI suite bundle ${stalled} has run for more than ${bundle_timeout}s (WHEELS_CLI_BUNDLE_TIMEOUT); stopping the run."
    echo "Last spec started: $(last_spec)"
    pid="$(lsof -ti :"$port" -sTCP:LISTEN 2>/dev/null | head -1 || true)"
    if [ -n "$pid" ]; then
      dump_from=$(( $(wc -l < "$server_log") + 1 ))
      kill -QUIT "$pid" 2>/dev/null || true
      sleep 3
      dump="$(tail -n +"$dump_from" "$server_log" | { grep -a -v '^\[cli-suite\]' || true; })"
      echo "── Threads running CFML (the stalled request among them) ──"
      printf '%s\n' "$dump" | awk 'BEGIN { RS = ""; ORS = "\n\n" } /\$cf\./' | head -200
      echo "── Full server JVM thread dump (pid ${pid}) ──"
      printf '%s\n' "$dump"
    else
      echo "No listener on port ${port}; no thread dump."
    fi
  } >&2
  kill "$curl_pid" 2>/dev/null || true
  wait "$curl_pid" 2>/dev/null || true
  echo "000"
  exit 3
fi

wait "$curl_pid" 2>/dev/null || true
code="$(cat "$code_file" 2>/dev/null)"
[ -n "$code" ] || code="000"
case "$code" in
  200|417) ;;
  *)
    last="$(last_bundle_event)"
    case "$last" in
      *" start "*) echo "::error::The CLI suite request ended (HTTP ${code}) while bundle $(echo "$last" | awk '{print $4}') was running (last spec started: $(last_spec))." >&2 ;;
    esac
    ;;
esac
echo "$code"
