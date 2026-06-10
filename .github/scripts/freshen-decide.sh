#!/usr/bin/env bash
# Maps a PR's GitHub mergeStateStatus to a freshen action.
#   BEHIND -> update (merge develop in, non-destructive)
#   DIRTY  -> dispatch-resolver (real conflict)
#   *      -> skip (CLEAN/UNSTABLE/BLOCKED/UNKNOWN are not our job)
set -euo pipefail
case "${1:-}" in
  BEHIND) echo "update" ;;
  DIRTY)  echo "dispatch-resolver" ;;
  *)      echo "skip" ;;
esac
