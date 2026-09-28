#!/usr/bin/env bash
# One checked Oracle readiness probe for the compat matrix (#3738).
#
# Exit 0 only when the wheelstestdb service executed a query and returned the
# expected row. Anything else exits 1 and prints SQL*Plus's output on stderr.
#
# The previous probe was
#   docker exec wheels-oracle-1 sqlplus -S user/pass@... <<< "SELECT 1 FROM DUAL; EXIT;"
# `docker exec` without -i does not forward stdin, so the query never reached
# SQL*Plus: it logged in (or failed to), read EOF, and exited. Its exit
# status said nothing about whether the service could run SQL. This version
# attaches stdin, uses -L (no re-prompt after a failed logon), makes SQL and
# OS errors exit non-zero, and checks the query result itself.
#
# Usage: tools/ci/oracle-ready.sh            (container: wheels-oracle-1)
#        ORACLE_CONTAINER=name tools/ci/oracle-ready.sh
set -uo pipefail

CONTAINER="${ORACLE_CONTAINER:-wheels-oracle-1}"
CONNECT="${ORACLE_CONNECT:-wheelstestdb/wheelstestdb@//localhost:1521/wheelstestdb}"

# The sentinel is built by concatenation so the literal only appears in the
# output when the SELECT actually ran.
OUT=$(docker exec -i "$CONTAINER" sqlplus -S -L "$CONNECT" 2>&1 <<'SQL'
WHENEVER OSERROR EXIT FAILURE
WHENEVER SQLERROR EXIT FAILURE
SET HEADING OFF FEEDBACK OFF PAGESIZE 0 VERIFY OFF
SELECT 'WHEELS' || '_READY' FROM DUAL;
EXIT SUCCESS
SQL
)
RC=$?

if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -q 'WHEELS_READY'; then
  exit 0
fi

{
  echo "Oracle probe failed (sqlplus exit ${RC}). Output:"
  printf '%s\n' "$OUT" | tail -n 20
} >&2
exit 1
