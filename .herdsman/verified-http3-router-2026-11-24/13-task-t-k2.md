# Task t-k2: K2 verified URL canonicalization (E03 US-011..015, plus E08)

Branch `local/t-k2-canon` from the spec HEAD. Worktree `<repo-parent>/worktrees/t-k2`.
Report file `<route>/reports/t-k2.md`.

Due: set at launch from `date` (shell blocked; no launch yet). Unfinished at due time: report
from what exists with `STATUS: gaps`.

Must prove subset: P1 (canonicalizer totality/panic-freedom) and P4 (containment plus
idempotence as defined for canonical values/serialization). Proofs run against the approved
Phase-1 spec; no undocumented `assume`/`external_body`.

## Problem
Path confusion (encoded `/`, NUL, traversal, double decoding) causes routing bypasses. K2 must
reduce every raw `:path` byte string to one canonical representation, once, before matching.

## Scope
1. US-011: validate encoded length, `%` syntax, and configured limits before expensive decode;
   reject malformed `%`, NUL, and forbidden encoded separators with typed rejections, never
   panic; in-bounds iteration and arithmetic safety proved.
2. US-012: decode exactly once; validate decoded UTF-8; no Unicode normalization; never
   re-decode downstream; pin the approved residual-escape policy with double-encoding tests.
3. US-013: spec-approved `.`/`..`/repeat-separator/root-escape/trailing-slash handling;
   output has no standalone `.`/`..`, no empty interior segments, no decoded `/` in a
   segment; case and trailing-slash decisions preserved; unsafe paths rejected, not rerouted.
4. US-014: Verus proves the executable canonicalizer refines the canonicalization spec and
   establishes P4 plus P1, with termination shown and no proof shortcuts.
5. US-015: fuzz raw path bytes, malformed escapes, traversal, Unicode, limits, double decode;
   differential-test the reference canonicalizer on the shared semantic subset; 24 h campaign
   with zero unresolved mismatches, logs/seeds/corpus retained; every issue gets a regression
   case.

## Out of scope
K3/K4/K1 logic, adapter, dispatch, benchmarks. Owns canonicalizer files and its spec tests;
shared decision/error types are fixed cross-task rules cited by number.

## Overlap
Later tasks consume the canonical representation byte for byte; any serialization change is a
`handoff:` line to t-k3k4, never an edit there.

## Acceptance
- E03 Definition of Done: specs/proofs pass, security regression cases pass, 24 h
  differential-fuzz evidence archived with zero unresolved mismatches.
- Canonical outputs contain no `.`/`..`/empty-interior/decoded-slash-in-segment; idempotence
  holds as specified; unsafe paths yield typed rejection, not an alternate handler.
