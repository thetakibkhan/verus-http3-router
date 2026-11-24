# Task t-k1: K1 HTTP/3 pseudo-header validation (E06 US-028..033)

Branch `local/t-k1-headers` from the spec HEAD. Worktree `<repo-parent>/worktrees/t-k1`.
Report file `<route>/reports/t-k1.md`.

Due: set at launch from `date` (shell blocked; no launch yet). Unfinished at due time: report
from what exists with `STATUS: gaps`.

Must prove subset: P7 (ordered header-list validity per the approved RFC-based scope) plus
applicable P1/P8 (traversal bounds, termination). No claim of full HTTP/3 conformance from K1.

## Problem
Ambiguous header lists (duplicates, misplaced pseudo-headers, missing fields, CONNECT forms)
must be rejected before routing, using the ordered decoded bytes TQUIC supplies.

## Scope
1. US-028: byte-oriented ordered header-list input contract preserving order and duplicates;
   documented split of TQUIC-handled framing vs K1-verified rules; header count/size/segment
   bounds represented and validated.
2. US-029: in-scope ordinary requests enforce uniqueness, presence, pseudo-before-regular
   ordering, and field-name rules for `:method`, `:scheme`, `:path`, authority/Host per the
   approved RFC 9114/9110 reading; distinct typed failures for duplicates, missing fields,
   bad ordering, and prohibited forms; valid plus invalid sequence tests.
3. US-030: recognise valid CONNECT and extended CONNECT in the approved subset as
   `UnsupportedConnect`; keep malformed CONNECT distinguishable; never dispatch CONNECT to
   a path route.
4. US-031: structured results (valid interpretation or specific variant); documented mapping
   of variants to stream-error vs HTTP-level outcomes; no async writes, no blanket HTTP 400.
5. US-032: Verus P7 proof over the approved header specification plus P1/P8 for traversal;
   review record states K1 is not full-protocol conformance.
6. US-033: adversarial corpus (duplicates, pseudo-after-regular, missing fields, oversized
   lists, bad names, authority conflicts, CONNECT variants) with expected kernel plus
   integration outcomes; automated suite, no unexpected panics.

## Out of scope
QPACK internals, adapter bytes, matching, dispatch. Owns validator plus corpus; shared
`Decision`/error enums are fixed cross-task rules.

## Overlap
Defines what the adapter must deliver losslessly; adapter deviations arrive as `handoff:`
lines to t-integrate, never edits there.

## Acceptance
- E06 Definition of Done: K1 validates supported semantics, P7/P1/P8 proofs pass in scope,
  adversarial suites pass, and docs disclaim full-protocol conformance.
