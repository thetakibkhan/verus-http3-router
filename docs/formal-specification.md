# Formal specification (DRAFT — pending independent sign-off)

Status: draft stub for Phase-1 work. Nothing here is approved, nothing is proved, and no
Verus code has been run. The [PRD](/home/takib/Documents/arafat-vai-office/router/docs/VERIFIED_HTTP3_ROUTER_PRD.md)
is the requirements baseline; the [boss plan](/home/takib/Documents/arafat-vai-office/router/docs/verus-verified-router-plan.md)
is the architecture roadmap. Every OPEN item below must be resolved or explicitly blocked
before any P1–P8 claim (E02 gate).

## 1. Route grammar (proposed)
- A route has: method, pattern, explicit priority, unique non-zero/stable ID.
- Pattern segments are literals, `:param` (exactly one nonempty canonical segment), or one
  terminal `*catchall` (zero or more remaining segments, terminal only).
- Parameter names are unique within a pattern. Matching is case-sensitive; `/users` and
  `/users/` are distinct canonical paths.
- OPEN: ID type and range, duplicate-ID policy, priority numeric range and ties across
  method plus HEAD fallback (PRD deferred item 3).

## 2. Decision types (proposed)
- `Route { route_id, params, effective_method }` or typed `Reject`: `NotFound`,
  `MethodNotAllowed { allowed }`, malformed-header, unsafe-path, limit-violation,
  `UnsupportedConnect` variants.
- OPEN: exact error-to-response and error-to-stream-error mapping, OPTIONS precedence and
  allowed-method ordering, unknown-path OPTIONS outcome, authority/Host scope, CONNECT
  recognition scope (PRD deferred items 4-5).

## 3. Reference functions (illustrative sketches, NOT compiled, NOT proved)
- `canon(path_bytes) -> CanonicalPath | Reject`: one decode pass, UTF-8 check, dot-segment
  removal, strict trailing-slash preservation. Recursion carries an explicit decreases
  measure on input length; respecify before proving.
- `seg_matches(pattern, segments) -> bool`: literal equality, `:param` one segment,
  terminal catch-all for the tail only.
- `match_spec(table, method, canonical_path) -> Decision`: linear conceptual scan, highest
  explicit priority wins; equal-priority overlap is rejected at build time, never resolved
  at serve time.
- Table well-formedness predicate: grammar-valid, IDs unique, no same-method
  equal-priority overlap, handler mapping complete, limits respected.
- OPEN: residual `%` handling, doubled separators, root-escaping `..`, encoded backslash,
  query strings, dot-segment/trailing-`/` interactions (PRD deferred items 1-2).

## 4. P1-P8 traceability (statements proposed, all evidence PENDING)
| Property | Formal statement ref | Implementation target | Evidence |
|---|---|---|---|
| P1 totality | canon/match/header traversal terminates, no panic/overflow | Sections 3, 5, 6 | PENDING: Verus run |
| P2 refinement | `match_exec` equals `match_spec` on valid tables/requests | Section 3 scan | PENDING: Verus run |
| P3 determinism | accepted tables admit a unique maximum | table predicate | PENDING: Verus run |
| P4 containment | no `.`/`..`/empty-interior/decoded-`/`; idempotent canon | `canon` | PENDING: Verus run |
| P5 confinement | prefix-mounted routes see only that segment prefix | matcher | PENDING: Verus run |
| P6 soundness | captures are wildcard positions; pattern+captures rebuild path | matcher | PENDING: Verus run |
| P7 headers | ordered-list validity per approved RFC reading | Section 6 | PENDING: Verus run |
| P8 bounds | validated limits; loop/work bounds for scan and traversal | Sections 5-6 | PENDING: Verus run |

## 5. Matching and method behaviour (proposed)
- Unknown path yields `NotFound`; known path with no permitted method yields
  `MethodNotAllowed` with a deterministic duplicate-free allowed list.
- Explicit HEAD wins; otherwise HEAD falls back to GET routing with body suppression
  downstream. OPTIONS follows the approved precedence (OPEN item 4).
- Higher explicit priority wins; equal-priority overlaps are build-time errors naming both
  routes.

## 6. Header validation scope (proposed, RFC text must be verified)
- Input is the ordered decoded header list, duplicates and order preserved.
- In-scope ordinary requests enforce presence, uniqueness, pseudo-before-regular ordering,
  and field-name rules for `:method`, `:scheme`, `:path`, authority/Host.
- Valid CONNECT and extended CONNECT in the approved subset yield `UnsupportedConnect`;
  malformed CONNECT stays distinguishable; CONNECT never reaches a path route.
- WARNING: the boss plan marks its RFC 9114 rules as from memory. Phase 1 must verify
  every rule against the RFC text before sign-off. K1 never claims full-protocol
  conformance.

## 7. Bounds model (structure proposed, numbers OPEN)
- Startup-validated, runtime-immutable limits on header count/sizes, encoded/decoded path
  sizes, segment count/length, route count/pattern length, matcher operations.
- OPEN: numeric defaults and the maximum envelope (PRD deferred item 6); p99 budget number
  after baseline (item 7).

## 8. Adversarial examples (PROPOSED expectations, not approved)
| Input | Proposed outcome | Rule |
|---|---|---|
| `/a/../b` | canonical `/b` then match | dot-segment removal |
| `/%2e%2e/` | rejected or canonicalised per OPEN item 1 | encoded dot |
| `//x` | single-separator normalisation per spec | repeated separator |
| `%2F`, NUL, bad `%` | typed rejection | forbidden encoding |
| `/api/users2` vs prefix `/api/users` | no match (segment, not string, prefix) | P5 |
| trailing `/` variants | distinct paths, never merged | strict slashes |
| equal-priority overlap | build-time conflict error | P3 |
| HEAD with/without explicit route | fallback vs explicit | method rules |
| OPTIONS, unknown path | per OPEN item 4 | discovery |
| CONNECT forms | `UnsupportedConnect`, never path-routed | special forms |

## 9. Deferred decisions (PRD Section 5 items 1-7)
Residual `%`; separator/root-escaping/backslash/query/dot-plus-slash cases; ID/dup/priority
ties; OPTIONS precedence/ordering; authority/Host and CONNECT scope; numeric limits; p99
budget. Each needs spec sign-off, never silent assumption.

## 10. Sign-off (empty)
Reviewer: undecided. Date: undecided. Comments: none. Revisions: none. E02 gate: NOT passed.
No story is Done on the basis of this stub.