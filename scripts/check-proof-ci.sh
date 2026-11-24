#!/usr/bin/env bash
set -euo pipefail

logs=${1:-target/phase0-proof}
mkdir -p "$logs"
bash scripts/check-proof.sh versions 2>&1 | tee "$logs/versions.log"

valid_exit=0
bash scripts/check-proof.sh valid > "$logs/valid.log" 2>&1 || valid_exit=$?
cat "$logs/valid.log"
printf 'valid_exit=%s\n' "$valid_exit" | tee -a "$logs/valid.log"
if (( valid_exit != 0 )); then
    exit "$valid_exit"
fi
grep -Eq 'verification results:: [1-9][0-9]* verified, 0 errors' "$logs/valid.log"

invalid_exit=0
bash scripts/check-proof.sh invalid > "$logs/invalid.log" 2>&1 || invalid_exit=$?
cat "$logs/invalid.log"
printf 'invalid_exit=%s\n' "$invalid_exit" | tee -a "$logs/invalid.log"
if (( invalid_exit != 1 )) ||
    ! grep -Fq 'postcondition not satisfied' "$logs/invalid.log" ||
    ! grep -Eq 'verification results:: [0-9]+ verified, 1 errors?' "$logs/invalid.log"; then
    echo 'Expected the verifier to reject the mutated postcondition' >&2
    exit 1
fi
printf '%s\n' 'PASS: valid proof verified and invalid proof rejected'
