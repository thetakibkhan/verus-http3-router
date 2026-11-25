# Independent review: hosted Phase 0 proof workflow and artifact

Review contract: `.herdsman/verified-http3-router-2026-11-24/21-review-hosted-phase0.md`
Workflow: **Verus smoke proof**
Run: **45646863052**
Branch: `local/t-phase0-spike`
Checked SHA: `eedcc026b4b3c450fe247df95e812e620473ee82`

## Findings

No P0/P1 findings.

## Review checks

- The workflow triggers on push and pull request, names the run `Verus smoke proof`, and uploads `phase0-proof-${{ github.sha }}`. The report records run 45646863052 as a successful push run on `local/t-phase0-spike` at the checked SHA; the artifact name includes that SHA.
- Preserved `versions.log` records the same checked SHA, proof SHA-256, Rust/Cargo 1.100.0, Verus `0.2026.11.22.1ce6a59`, and Z3 4.16.0.
- `valid.log` records `1 verified, 0 errors` and `valid_exit=0`. `invalid.log` records the expected postcondition failure, `0 verified, 1 errors`, and `invalid_exit=1`.
- SHA-256 values match the report: `versions.log` `9a5b1d51a5ab15b22937ceeecf64ae92097f2cac5c47267a03a693b800ecf7d5`; `valid.log` `b2cb50f59eadc24330571d87a1fc0ff925021755ab683fbbcbc829d9a8dfdff1`; `invalid.log` `f92742c65bc68120c410651042a6a343accaabb112041fa4657566b989d60c6e`.
- The TCB and Phase 0 report do not claim P1–P8 proofs. US-003/US-005 hosted evidence is recorded as complete, with independent review pending before final acceptance. The Node.js deprecation annotation is nonblocking.
- No checks were rerun for this report.

VERDICT: pass
