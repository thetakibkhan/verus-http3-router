# Task t-phase0: Phase-0 spike (E01 US-001..005)

Branch `local/t-phase0-spike` from repo HEAD. Worktree `<repo-parent>/worktrees/t-phase0`.
Report file `<route>/reports/t-phase0.md`.

Due: set at launch from `date` (shell blocked; no launch yet). If unfinished at due time, stop
starting new work, write the report from what exists with `STATUS: gaps`, and reply with its path.

Must prove subset: P1/P8 groundwork only insofar as the toolchain pins make later proofs
reproducible. No P1–P8 claim is closed in this task.

## Problem
The repo has no workspace, pins, CI verification, or TQUIC demo yet (docs only). Phase 0 must
prove the toolchain and headers path are real before specs are written.

## Scope
1. US-001: Cargo workspace with routing-kernel crate, adapter crate, and HTTP/3 server example;
   `cargo build` and `cargo test` pass with no network-dependent tests; README states each
   crate's responsibility and verification status.
2. US-002: pin Rust, Verus revision, Z3, TQUIC, and lockfile; README gives exact setup and
   version-check commands; clean-machine run lists versions.
3. US-003: minimal Verus proof in CI that fails on a deliberately invalid proof; CI publishes
   verifier version, pass/fail, and checked revision.
4. US-004: minimal TQUIC server receiving an HTTP/3 `Headers` event from a documented client;
   record API version and constraints shaping adapter design (order/duplicates preserved).
5. US-005: spike report with build/proof/demo commands and outcomes, incompatibilities with
   repro steps; gate: US-001..004 pass.

## Out of scope
Kernel logic, specs, proofs beyond the smoke proof, adapter behaviour, benchmarks. Do not touch
files owned by later phase tasks except the workspace skeleton and CI they all build on.

## Overlap
None yet; this is the first branch. Later tasks rebase onto its HEAD with a merge, never a
rebase of this branch once reviewed.

## Acceptance
- Fresh checkout reproduces `cargo build`, `cargo test`, one passing Verus verification, and
  one observed HTTP/3 `Headers` event, all from documented commands.
- CI rejects an invalid proof; logs show verifier version and revision.
- No network access to unrelated services in tests; no secrets committed.
