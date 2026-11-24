#!/bin/bash
# Route run-check wrapper — UNTESTED (shell blocked, never executed).
# Before first use, once the shell works:
#   1. Set HERDSMAN_LOAD_LIMIT from the machine idle load plus a margin,
#      and HERDSMAN_MIN_FREE to a free-memory percent.
#   2. chmod +x this file.
#   3. Test: one real check through it, plus one run with HERDSMAN_PROBES=off.
# Until then every agent report records checks as not run under gaps:.
export HERDSMAN_LOAD_LIMIT=${HERDSMAN_LOAD_LIMIT:-UNSET_IDLE_PLUS_MARGIN} HERDSMAN_MIN_FREE=${HERDSMAN_MIN_FREE:-UNSET_FREE_PCT}
exec herdsman run-check "$@"
