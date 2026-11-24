# Task t-spec: Phase-1 specifications and sign-off (E02 US-006..010)

Branch `local/t-spec-phase1` from the Phase-0 HEAD. Worktree
`<repo-parent>/worktrees/t-spec`. Report file `<route>/reports/t-spec.md`.

Due: set at launch from `date` (shell blocked; no launch yet). If unfinished at due time, write
the report from what exists with `STATUS: gaps` and reply with its path.

Must prove subset: none closed here. This task produces the statements P1–P8 will be proved
against, plus the traceability map reviewers audit.

## Problem
P1–P8 cannot be proved until the grammar, reference functions, obligations, and adversarial
examples are written and independently approved. PRD Section 5 items 1–7 are still open.

## Scope
1. US-006: route grammar (literals, `:param`, terminal `*catchall`, methods, IDs, priorities)
   with disallowed-pattern examples; typed outcomes for route/404/405/malformed/CONNECT/limits;
   case-sensitivity, strict trailing slashes, empty catch-all, and priority examples.
2. US-007: pure reference `spec fn`s for canonicalization, pattern matching, table
   well-formedness, priority selection, and capture; linear conceptual scan; domains, invalid
   inputs, preconditions, and termination measures stated.
3. US-008: P1–P8 traceability matrix (property -> formal statement -> implementation target ->
   evidence); proved-kernel vs assumed-interface vs unverified-surroundings boundary; numeric
   bounds as a verifiable model, no vague speed/safety words.
4. US-009: adversarial spec examples with approved expected outcomes: `/a/../b`, `/%2e%2e/`,
   `//x`, encoded slash/backslash, invalid `%`, mixed case, trailing `/`, overlaps, equal
   priorities, HEAD fallback, OPTIONS, 404/405, empty catch-all.
5. US-010: resolve or explicitly block every Section 5 deferred item (residual `%`, doubled
   separators, root-escaping, query/dot interactions, ID/dup/priority ties, OPTIONS precedence
   and ordering, authority/Host scope, CONNECT scope, numeric limits, p99 budget process);
   nothing silently assumed. Independent reviewer sign-off with name, date, comments, and
   revisions recorded.

## Out of scope
Executable kernel code and proofs (later phases). Spec examples must be executable as spec
tests, not as implementation.

## Overlap
Defines the wire text later tasks code against (grammar, decision types, limits): commit it
first; later changes are `handoff:` lines plus a spec amendment, never silent edits.

## Acceptance
- E02 Definition of Done: reference spec, P1–P8 contract, and adversarial examples carry
  independent written approval from someone other than the author.
- Every P-property maps to a formal statement and a planned evidence artifact.
- All seven Section 5 items are resolved or explicitly blocked with owner and rationale.
