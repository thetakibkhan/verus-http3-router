# Task t-integrate: TQUIC integration, security, benchmarks, handoff (E07+E08+E09+E10)

Branch `local/t-integrate-demo` from the combined accepted heads (Phase 0..4). Worktree
`<repo-parent>/worktrees/t-integrate`. Report file `<route>/reports/t-integrate.md`.

Due: set at launch from `date` (shell blocked; no launch yet). Unfinished at due time: report
from what exists with `STATUS: gaps`.

Must prove subset: no new kernel proofs here; this task preserves every prior proof (same
verified code path), audits the unverified boundary, and gathers the evidence E08–E10 demand.

## Problem
A proved kernel with a lossy adapter, unmapped handlers, or unmeasured performance is not a
shippable router. This task wires the kernel to real HTTP/3 traffic and assembles the
acceptance package.

## Scope
1. US-034: thin lossless TQUIC adapter (ordered name/value bytes, duplicates intact, no
   second decode, no reorder, no handler selection); documented assumptions; small reviewable
   size; independently reviewable code.
2. US-035: immutable route-ID to async-handler dispatch map, validated before serving;
   successful decisions dispatch exactly the mapped handler with capture data; missing
   mappings fail startup loudly.
3. US-036: response/stream-error mapping: valid routes get demo responses; 404/405/HEAD/
   OPTIONS map with correct body and method-header behaviour; malformed messages follow
   stream-error semantics, not blanket HTTP 400; CONNECT never tunnels.
4. US-037: end-to-end demo (literal, `:param`, catch-all, GET/POST) with README server plus
   client commands covering valid route, 404, 405, HEAD, OPTIONS, malformed path, and
   malformed headers.
5. US-038: `h3spec`-equivalent interop run on pinned config; in-scope scenarios pass;
   unsupported items recorded, never silently passed; command, version, results, traces kept.
6. US-039: independent adapter audit (order/duplicates/lifetimes/bounds/error translation)
   plus `cargo-fuzz` on raw ordered header lists; crashes or discrepancies fixed or tracked
   as release blockers; audit plus seeds/corpus kept.
7. US-040..044: regression corpus (encoded dots, double encoding, slashes, backslashes,
   rootless targets, overlong/invalid UTF-8, traversal, size edges) with expected typed
   decisions; comparative routing tests on the documented subset with every disagreement
   triaged; proof-mutation evidence; fast PR gates plus longer release gates; failure triage
   log with severity, repro, owner, resolution; deliberate differences linked to spec clauses.
8. US-045..047: reproducible baseline workloads (small/medium/large, literal/param/catch-all,
   no-match, adversarial); p50/p95/p99 plus throughput with methodology; numeric p99 budget
   agreed with reviewer after baseline, enforced as release gate.
9. US-049..053: `TCB.md` registry (TQUIC/QUIC/TLS/QPACK, adapter, dispatch, handlers, Rust,
   Verus, Z3, every `external_body`/`assume_specification`/`assume` with rationale, owner,
   review); CI check blocking unregistered exemptions; P1–P8 evidence report on the shipped
   path; public API docs with compiling examples and trust-boundary diagram; full review
   package; evidence-based sign-off (proofs, demo, security, interop, benchmarks, TCB,
   approver, date, commit).

## Out of scope
Changing kernel semantics or adding the Trie (US-048 is a separate conditional task).
Cross-task fixes land here as integrator-owned changes with regression tests.

## Overlap
Merges accepted branch heads in fixed order t-phase0, t-spec, t-k2, t-k3k4, t-k1; applies all
`handoff:` lines; fixes only integration breakage plus final-review findings (test first).

## Acceptance
- E07–E10 Definitions of Done: live HTTP/3 demo routes through the verified kernel; adapter
  audit, fuzz, interop, regression, mutation, benchmark, TCB, evidence, and sign-off artefacts
  all recorded. No unresolved security-critical or correctness-critical issue.
