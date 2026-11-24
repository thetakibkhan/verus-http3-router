# Task t-k3k4: K3 table validation plus K4 linear matching (E04+E05, plus E08)

Branch `local/t-k3k4-table-match` from the spec HEAD. Worktree
`<repo-parent>/worktrees/t-k3k4`. Report file `<route>/reports/t-k3k4.md`.

Due: set at launch from `date` (shell blocked; no launch yet). Unfinished at due time: report
from what exists with `STATUS: gaps`.

Must prove subset: P1 (matcher totality), P2 (`match_exec` refines `match_spec`), P3 (table
well-formedness implies a unique winner), P5 (prefix confinement), P6 (exact capture plus
reconstruction), P8 (verified bounds/termination). No undocumented proof shortcuts.

## Problem
Ambiguous or malformed tables and an unsound matcher silently misroute. K3 must make bad
tables unbuildable; K4 must deterministically return the unique highest-priority match.

## Scope
1. US-016: declarative Rust builder (literal, `:param`, terminal catch-all, explicit
   priority/ID) with one startup `build`/`compile`; typed errors, never silent acceptance.
2. US-017: reject empty/dup parameter names, misplaced or multiple catch-alls, bad
   method/ID, duplicate route IDs with ID/position plus reason; boundary tests at limits.
3. US-018: detect every overlapping same-method equal-priority pair (literal-vs-param and
   catch-all intersections); structured conflict error naming both routes; higher priority
   wins; Verus well-formedness invariant backing P3.
4. US-019: frozen read-only compiled table, shareable via `Arc`, no public mutator, no hot
   reload; updates rebuild plus restart.
5. US-020: startup handler-completeness check: every route ID maps to exactly one dispatch
   entry; missing/duplicate mappings are detailed startup errors; mapping immutable at serve
   time.
6. US-021: Verus proves accepted-table invariants including overlap/priority rules and size
   bounds; limit violations rejected without panic/overflow; method/syntax assumptions explicit.
7. US-022: linear matcher over compiled table plus canonical request only; method, segment,
   and priority handling; unique highest-priority match or typed no-match.
8. US-023: `:param` captures exactly one segment, catch-all zero or more; approved
   trailing-slash representation; pattern-plus-captures reconstructs the canonical path (P6).
9. US-024: `NotFound` vs `MethodNotAllowed` (with allowed methods, deterministic, no dupes);
   explicit HEAD wins, else HEAD falls back to GET with body suppression downstream; OPTIONS
   per approved precedence, including HEAD-implied-by-GET and unknown-path behaviour.
10. US-025..027: P2/P3/P1/P5/P6/P8 proofs over all valid tables and in-scope requests,
    covering success plus each rejection class; empty-table, maximal-input, and
    limit-rejection tests; K2-serialization changes arrive as `handoff:` lines.

## Out of scope
K1 header rules, adapter bytes, async dispatch/handlers, benchmarks. Owns table compiler,
matcher, and their tests; header/error-type blocks shared with t-k1 are fixed by rule number.

## Overlap
Consumes K2 output bytes exactly; produces the `Decision` type the integrator and dispatch
use. Cross-file fixes go to the integrator as `handoff:` lines.

## Acceptance
- E04 plus E05 Definitions of Done: immutable, syntactically valid, handler-complete tables;
  P2/P3/P5/P6/P8 plus applicable P1 obligations proved; mutants of selection, priority, and
  capture fail verification; route-behaviour suites green.
