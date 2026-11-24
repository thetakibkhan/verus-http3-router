#!/bin/bash
# Load snapshot: load 1.09 of 8 cores, 41% free memory.
export HERDSMAN_LOAD_LIMIT=8 HERDSMAN_MIN_FREE=10
exec herdsman run-check "$@"
