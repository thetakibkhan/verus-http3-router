# Product Requirements Document (PRD)
## Verus-Verified HTTP/3 Request Router on TQUIC

**Status:** Requirements baseline — implementation pending  
**Version:** 1.0  
**Date:** 24 November 2026  
**Primary input:** *Plan: A Verus-Verified Request Router on TQUIC (HTTP/3)* (boss's draft, 23 November 2026)  
**Decision record:** 30 agreed PRD choices (Q1–Q30)  
**Intended audience:** Project owner, implementer, independent specification reviewer, security reviewer  
**Note:** This document defines V1 acceptance requirements. It does **not** assert that implementation, proofs, or testing have been completed.

---

## 1. Executive summary

Build a **reusable Rust routing library** whose security-sensitive HTTP/3 request routing logic is **formally verified using Verus**, plus a **working TQUIC-based HTTP/3 server example** demonstrating real requests. The verified, synchronous kernel accepts decoded header name/value byte pairs and an immutable, validated route table; it returns either a route ID with captured parameters or a typed rejection. TQUIC networking, the thin adapter, and asynchronous application handlers are outside the formal verification boundary.

V1 acceptance requires machine-checked evidence for all eight properties **P1–P8**, RFC-aligned header processing for the subset in scope, security testing, independently reviewed specifications and adapter, reproducible builds, and benchmark results meeting a performance budget agreed **after** baseline measurements.

### Goals
1. Provide correct, deterministic method/path routing with literal, parameter, and terminal catch-all segments.
2. Eliminate specified classes of URL interpretation bugs through verified canonicalization and prefix-confinement guarantees.
3. Verify the implementation against a human-reviewed mathematical routing specification.
4. Demonstrate practical use with real HTTP/3/TQUIC traffic without bringing async code into the verified kernel.
5. Make verification claims reproducible and honest about their assumptions and unverified surroundings.

### Non-goals for V1
- Proving TQUIC, TLS, QUIC, QPACK, or the full HTTP/3 protocol implementation correct.
- General-purpose web framework features (middleware ecosystem, JSON validation, ORM, authentication, authorization).
- Hostname/virtual-host route selection (authority is validated, not used as a routing discriminator).
- Regex, typed route parameters, optional segments, or catch-all wildcards in the middle of patterns.
- Dynamic route registration or hot reloading.
- CONNECT/extended CONNECT tunneling.
- Production orchestration, monitoring platform, or SLA management.
- A verified Trie unless the linear matcher fails the agreed performance target and optimization is separately approved.

### Definitions
- **Verified kernel:** synchronous Verus-verified logic for K1 headers, K2 canonical paths, K3 table validation, and K4 matching.
- **Routing decision:** `Route { route_id, params, effective_method }` or a typed `Reject` result; exact Rust types finalized in design review.
- **Canonical path:** an internal representation produced by the one-time decoding and normalization policy; never re-decoded downstream.
- **TCB:** trusted computing base and exclusions documented in `TCB.md` (including compiler, verifier/solver, external assumptions, TQUIC, adapter, and downstream dispatch/handlers as relevant).
- **Source of truth:** the approved formal specification, not a third-party router's incidental behavior.

---

## 2. Confirmed product decisions (Q1–Q30)

| ID | Confirmed decision |
|---|---|
| Q1 | Reusable Rust routing crate + working TQUIC HTTP/3 server example |
| Q2 | Path-only selection (method + canonical path); validate authority, do not select by host |
| Q3 | Literal, named parameter, and terminal catch-all patterns |
| Q4 | Case-sensitive matching and strict trailing-slash distinction |
| Q5 | Build and validate an immutable route table at startup |
| Q6 | Higher explicit priority wins; reject overlapping equal-priority routes at startup |
| Q7 | Strict canonicalization: decode once, normalize dot segments, reject malformed/unsafe paths, encoded `/` and NUL |
| Q8 | Strict RFC-aligned pseudo-header validation and typed error outcomes |
| Q9 | Configurable, startup-validated, runtime-immutable input/work limits with safe defaults |
| Q10 | P1–P8 machine-checked properties mandatory for final V1 |
| Q11 | Verified linear matcher; Trie only after demonstrated need |
| Q12 | Thin, lossless TQUIC adapter preserving header bytes, order, and duplicates |
| Q13 | Declarative Rust route-builder API |
| Q14 | Invalid route configuration returns detailed errors and blocks server startup |
| Q15 | Distinguish 404 path-not-found from 405 method-not-allowed; report allowed methods |
| Q16 | Automatic HEAD fallback to GET and automatic OPTIONS discovery behavior |
| Q17 | Recognize and explicitly reject CONNECT/extended CONNECT in V1, without tunnel support |
| Q18 | Process bytes; strictly validate decoded path UTF-8; no Unicode normalization |
| Q19 | Catch-all must be terminal; matches zero or more remaining segments |
| Q20 | Proofs, differential tests, fuzzing, mutation tests, regression and HTTP/3 integration tests |
| Q21 | `TCB.md` registry and CI checks for unrecorded trusted exemptions |
| Q22 | Benchmark first, agree p99 overhead budget second |
| Q23 | Pin compatible versions of Rust, Verus, Z3, TQUIC and other critical dependencies |
| Q24 | Independent review and approval of specifications |
| Q25 | Reproducible p50/p95/p99 and throughput benchmarks with release gate |
| Q26 | Complete reproducible source, proof, test, documentation and demo package |
| Q27 | Verified route ID -> separate immutable async-handler dispatch map |
| Q28 | Investigate every differential mismatch against the spec; document deliberate differences |
| Q29 | Independently audit and fuzz the adapter; run HTTP/3 interoperability tests |
| Q30 | Evidence-based final sign-off covering proofs, HTTP/3 functionality, security, benchmarking and reproducibility |

**Governance:** Any later change to one of these decisions requires a documented amendment, impact analysis on proofs/tests, and review.

---

## 3. Architecture and trust boundary

```text
UDP
  -> TQUIC: QUIC + TLS + QPACK + HTTP/3 events      [unverified by this project]
  -> Thin adapter: ordered (name bytes, value bytes) [unverified; audited + fuzzed]
  -> Verus-verified, synchronous kernel:
       K1  HTTP/3 request pseudo-header validation
       K2  percent-decode, canonicalize, validate path
       K3  compile/validate frozen route table
       K4  select highest-priority route, capture params
  -> Typed decision: Route(id, params) | Reject(reason)
  -> Immutable route-ID-to-handler dispatch           [unverified]
  -> Async application handler / HTTP/3 response      [unverified]
```

**Key architectural invariants**
- K1 sees enough original ordered decoded-header data to detect duplicate and misplaced pseudo-headers.
- Security-sensitive path decoding and routing are not silently duplicated in the adapter or handlers.
- A successful startup guarantees a well-formed immutable table and a corresponding handler for every route ID.
- A verified kernel result is not, by itself, a proof that networking, adapter, authorization policy, or handlers are correct.
- Response/stream handling must comply with applicable HTTP/3 error semantics; not every malformed request is necessarily represented by an HTTP 400 body.

---

## 4. Formal verification requirements: P1–P8

| Property | What must be proved within the modeled kernel | Primary epic |
|---|---|---|
| **P1: Totality / panic-freedom** | Kernel terminates with a typed decision for every represented input within the documented interface/assumptions; no indexing panics or arithmetic overflow | E03–E06 |
| **P2: Functional correctness** | Executable matching refines `match_spec` for valid compiled tables and canonical requests | E05 |
| **P3: Determinism / no ambiguity** | Accepted tables have no conflicting equal-priority matches; selection has a unique maximum under the priority policy | E04–E05 |
| **P4: Canonical-path containment** | Canonical outputs have no `.`/`..` segments, empty interior segments or decoded `/` within a segment; normalization is idempotent under the formally defined canonical representation | E03 |
| **P5: Prefix confinement** | Routes mounted under a prefix only receive paths with that canonical segment prefix | E05 |
| **P6: Parameter soundness** | Captures are exactly the wildcard-position segments and reconstruct the canonical matched path | E05 |
| **P7: Pseudo-header well-formedness** | The supplied header list is accepted only when the specified applicable HTTP/3 request-header constraints hold | E06 |
| **P8: Bounded work** | Explicit validated input/table limits and verified loop/work bounds for the linear matcher and preprocessing | E03–E06 |

**Proof-claim requirement:** For each property, record the spec function/lemma, implementation function, successful verifier command and tool versions, assumptions, review sign-off, and verification exclusions. Proof coverage is judged on the *actual code path shipped*, not detached illustrative examples.

---

## 5. Product behavior contract

### Routing
- A route has a unique nonzero/stable ID (exact ID validation documented), HTTP method, pattern, and explicit priority.
- Route patterns contain literal segments, `:param`, and at most one final `*catchall`; route parameter names must be unique within a pattern.
- Path comparison is case-sensitive; `/users` and `/users/` are distinct canonical paths.
- Named parameters capture a single nonempty canonical segment; catch-all captures zero or more remaining canonical segments. Its captured representation must preserve trailing-slash meaning so reconstruction is sound.
- At startup, detect every overlapping pair of same-priority patterns that could match the same method and canonical path; reject with an actionable conflict error. Higher priority resolves overlaps.
- Unknown path -> `NotFound` (404). Known path with unsupported method -> `MethodNotAllowed` (405) and allowed methods. `HEAD` falls back to a GET route when no explicit HEAD route matches. OPTIONS discovery returns supported methods according to a documented explicit-route precedence policy; include HEAD when implied by GET.
- CONNECT and extended CONNECT are recognized and deliberately unsupported; do not accidentally route them as ordinary methods or incorrectly reject valid special forms solely for lacking ordinary pseudo-headers.

### URL decoding and security
- Accept the raw HTTP/3 `:path` value as bytes, apply a single specified percent-decoding pass, then validate UTF-8 and normalize dot segments.
- Reject malformed percent sequences, encoded slash (`%2F`, case-insensitive), NUL, root-escaping traversals, and other explicitly specified unsafe path forms; test encoded backslash and doubled-encoding variants.
- Prevent a later stage from interpreting remaining escape syntax or applying an extra decoding pass that changes route meaning. Define and verify one canonical representation/serialization policy before implementation.
- Canonicalize request paths before matching or prefix checks. No Unicode NFC/NFD normalization in V1.
- Preserve the selected strict trailing-slash semantics after normalization; cover `.`, `..`, repeated separators, and trailing dot-segment edge cases in approved spec examples.

### Headers, errors and resource limits
- Validate applicable mandatory pseudo-headers, uniqueness, ordering, field-name rules, and special CONNECT handling with reference to RFC 9114 and RFC 9110, within the scope of the decoded headers exposed by TQUIC.
- Emit typed rejections that distinguish malformed-header protocol errors, unsupported methods, unsafe paths, limit violations, path-not-found, and method-not-allowed; map errors to HTTP responses or HTTP/3 stream errors as appropriate.
- Startup configuration permits safe limits on header counts/sizes, encoded and decoded path sizes, path segments and segment length, route count/pattern length, and bounded matcher operations. Numeric defaults and a globally allowed configuration envelope are to be selected and independently reviewed during Phase 1; no fabricated figures are deemed approved.

### Deferred detailed decisions requiring specification sign-off
These are **not new scope choices**; they are lower-level semantics needed to implement the already agreed choices without ambiguity:
1. Exact handling of literal `%` or residual percent-like text after one decode (double-decoding safety and canonical idempotence).
2. Exact treatment of doubled separators, root-escaping `..`, encoded backslashes, query strings and dot segments interacting with trailing `/`.
3. Route-ID type/range, duplicate ID policy, priority numeric range and ties across method/HEAD fallback.
4. Exact `OPTIONS` precedence, allowed-method ordering, and whether an unknown path's OPTIONS request returns 404.
5. Valid ordinary HTTP/3 `:authority`/Host compatibility and the precise scope of CONNECT recognition/rejection.
6. Numeric safe defaults and maximum allowed configurable limits, selected with test and benchmark evidence.
7. Benchmarked p99 routing overhead budget, established with the reviewer after baseline results.

**Gate:** Specification review must resolve these details before implementation claiming P1–P8 compliance can be accepted.

---

# 6. Epics, user stories and acceptance criteria

Every story below is a V1 requirement unless marked **Conditional**. Acceptance criteria (AC) are objective checks for the story. All technical artifacts must be committed with reproducible instructions and reviewed under the repository's normal approval process.

## E01 — Repository, toolchain, CI and feasibility spike
**Aligned phase:** 0  
**Epic outcome:** A reproducible environment can build a Rust crate, verify Verus code and receive HTTP/3 headers with TQUIC.

### US-001 — Initialize Rust workspace
**As a** developer, **I want** a structured Rust workspace **so that** kernel, adapter and demo can evolve separately.

**Acceptance criteria**
- AC1. A documented Cargo workspace contains a routing-kernel crate, an integration/adapter crate, and an example HTTP/3 server target; actual crate names are consistent.
- AC2. `cargo build` and `cargo test` pass in the pinned environment; no test requires network access to unrelated services.
- AC3. README explains the responsibility and verification status of each crate.

### US-002 — Pin the toolchain and dependencies
**As a** contributor, **I want** exact, known-compatible tool versions **so that** verification is reproducible.

**Acceptance criteria**
- AC1. Rust toolchain, Verus revision, Z3 version, TQUIC revision, and Cargo dependency lockfile are pinned or reproducibly provisioned.
- AC2. README contains exact setup and version-check commands for a fresh environment.
- AC3. A clean-machine or clean-container execution demonstrates the documented commands work; captured output lists versions.

### US-003 — Prove a minimal Verus example in CI
**As a** reviewer, **I want** automatic Verus verification **so that** proof regressions block merges.

**Acceptance criteria**
- AC1. A checked-in minimal Verus proof verifies with the pinned toolchain.
- AC2. CI runs verification and fails on a deliberately introduced invalid proof in a controlled test.
- AC3. CI publishes logs/artifacts containing verifier version, pass/fail status and checked revision.

### US-004 — Demonstrate TQUIC header reception
**As a** developer, **I want** a minimal HTTP/3 server **so that** TQUIC integration feasibility is established before kernel integration.

**Acceptance criteria**
- AC1. A reproducible TQUIC server accepts an HTTP/3 request from a documented compatible client.
- AC2. An HTTP/3 `Headers` event is observed and its decoded name/value list can be inspected without losing duplicates/order in the later adapter design.
- AC3. The spike records actual TQUIC API version and any constraints influencing adapter design.

### US-005 — Maintain Phase-0 evidence and risk log
**As a** project owner, **I want** spike evidence and known blockers **so that** implementation starts on a validated foundation.

**Acceptance criteria**
- AC1. A short spike report records build, proof and HTTP/3 demo commands and outcomes.
- AC2. Known toolchain/API incompatibilities and workarounds are documented with reproducible steps.
- AC3. Phase-0 sign-off requires US-001 through US-004 to pass.

**E01 Definition of Done:** Fresh checkout reproduces a Rust build, a passing Verus verification, and an HTTP/3 header event; CI rejects verification failure.

---

## E02 — Reviewed routing and security specifications
**Aligned phase:** 1  
**Epic outcome:** Independent reviewer approves mathematical and English behavior contracts before they become the verification target.

### US-006 — Define route grammar and decisions
**As a** kernel implementer, **I want** an exact route grammar and decision type **so that** implementation behavior cannot be inferred ambiguously.

**Acceptance criteria**
- AC1. Written grammar covers literals, `:param`, terminal `*catchall`, names, methods, IDs and priorities; disallowed patterns have examples.
- AC2. Typed outcomes are specified for route, 404, 405, malformed input, unsupported CONNECT and resource-limit rejection.
- AC3. Case sensitivity, strict trailing slashes, catch-all empty matches and priority ordering have concrete examples.

### US-007 — Specify pure reference functions
**As a** verifier, **I want** `spec fn` reference behavior **so that** executable code can be checked by refinement.

**Acceptance criteria**
- AC1. Reference functions define canonicalization, route-pattern matching, route-table well-formedness, priority selection and parameter capture.
- AC2. Selection uses a simple linear conceptual scan independent of optimized implementation details.
- AC3. All functions state domains, handling of invalid inputs and any preconditions; recursive specs provide termination measures where needed.

### US-008 — Specify all P1–P8 proof obligations
**As a** security reviewer, **I want** precise invariants and theorem statements **so that** each verification claim is auditable.

**Acceptance criteria**
- AC1. A traceability matrix maps P1–P8 to formal statements, implementation functions and planned evidence.
- AC2. The specification distinguishes proved kernel properties from interface assumptions and unverified TQUIC/adapter/handler behavior.
- AC3. Numeric configuration bounds and complexity assertions are expressed with a verifiable model rather than vague 'fast' or 'safe' language.

### US-009 — Specify adversarial and boundary examples
**As a** reviewer, **I want** executable specification examples **so that** ambiguous edge semantics are discovered early.

**Acceptance criteria**
- AC1. Proof examples or specification tests cover `/a/../b`, `/%2e%2e/`, `//x`, encoded slash, encoded backslash, invalid `%`, mixed-case paths and trailing `/`.
- AC2. Examples cover overlaps, equal priorities, HEAD fallback, OPTIONS discovery, 404/405 and empty catch-all captures.
- AC3. Each input has an approved expected output/rejection and an explanation of the relevant rule.

### US-010 — Obtain independent specification sign-off
**As a** project owner, **I want** another engineer to review the specification **so that** proof success is not confused with policy correctness.

**Acceptance criteria**
- AC1. A reviewer other than the author reviews the English spec and Verus mathematical definitions.
- AC2. Open semantic issues from Section 5 are resolved or explicitly blocked; none are silently assumed for production acceptance.
- AC3. Review record includes reviewer, date, comments, revisions and approval decision.

**E02 Definition of Done:** The reference specification, P1–P8 contract and adversarial examples receive independent written approval.

---

## E03 — K2: Verified URL canonicalization
**Aligned phase:** 2  
**Epic outcome:** Request paths are safely converted to an unambiguous canonical representation, with P1 and P4 evidence.

### US-011 — Validate raw path bounds and encoding
**As a** routing kernel, **I want** to reject malformed and oversized paths **so that** invalid input cannot cause unsafe access or resource exhaustion.

**Acceptance criteria**
- AC1. Validate encoded path length, percent-escape syntax and configured limits prior to expensive decoding.
- AC2. Inputs such as malformed `%` sequences, NUL and forbidden encoded separators return typed rejection rather than panic.
- AC3. Formal proof covers in-bounds iteration and arithmetic safety for validation logic.

### US-012 — Decode exactly once and validate UTF-8
**As a** kernel, **I want** a single controlled decoding step **so that** path interpretation is stable.

**Acceptance criteria**
- AC1. Valid percent encodings are decoded once; malformed encodings are rejected.
- AC2. Decoded path bytes are verified as valid UTF-8; invalid decoded sequences are rejected.
- AC3. No Unicode normalization is applied, and canonical paths are never re-percent-decoded in dispatch or handlers.
- AC4. Double-encoding tests establish the approved residual-escape handling policy.

### US-013 — Normalize path segments securely
**As a** kernel, **I want** deterministic dot-segment normalization **so that** path traversal cannot bypass routing prefixes.

**Acceptance criteria**
- AC1. Spec-approved handling of `.` and `..`, repeated separators, root escape and trailing slashes is implemented.
- AC2. Canonical output contains no standalone `.` or `..` segment, empty interior segments, or decoded slash inside a segment.
- AC3. Path transformation preserves the V1 case-sensitive and strict trailing-slash decisions.
- AC4. Unsafe paths produce an explicit rejection rather than an alternate handler.

### US-014 — Prove canonicalization correctness and idempotence
**As a** reviewer, **I want** executable canonicalization proven against the approved spec **so that** untested strings cannot change meaning unexpectedly.

**Acceptance criteria**
- AC1. Verus proves the executable canonicalizer refines the canonicalization spec for its declared input domain.
- AC2. Verus establishes P4 and P1 for the canonicalizer, including idempotence as precisely defined for canonical values/serialization.
- AC3. Proof obligations terminate and verify without undocumented `assume`/`external_body` shortcuts.

### US-015 — Fuzz and differentially test canonicalization
**As a** tester, **I want** adversarial validation **so that** incorrect specs and implementation blind spots can be found.

**Acceptance criteria**
- AC1. Fuzz targets exercise raw path bytes, malformed escapes, traversal, Unicode, length limits and double decoding.
- AC2. A reference canonicalizer is compared under a documented shared semantic subset; every mismatch is triaged.
- AC3. A 24-hour uninterrupted differential fuzz campaign produces **zero unresolved mismatches** for the agreed comparable semantics; logs, seed and corpus are retained.
- AC4. All discovered issues have regression cases.

**E03 Definition of Done:** Canonicalization specs/proofs pass, security regression cases pass, and the required 24-hour differential-fuzz evidence is archived.

---

## E04 — K3: Immutable route-table compiler and validation
**Aligned phase:** 3  
**Epic outcome:** Invalid or ambiguous route configurations never become active.

### US-016 — Provide declarative Rust route-builder API
**As an** application developer, **I want** to register method, path, priority and ID in Rust **so that** route configuration is readable and reusable.

**Acceptance criteria**
- AC1. Public API supports literal, parameter and terminal catch-all patterns and explicit priority/ID.
- AC2. Usage examples show registration and a single `build`/`compile` operation at startup.
- AC3. Invalid registrations return typed errors, not silent acceptance.

### US-017 — Validate route grammar and identifiers
**As a** kernel, **I want** to reject malformed patterns and duplicate identifiers **so that** the route table is structurally well formed.

**Acceptance criteria**
- AC1. Reject empty/invalid parameter names, duplicate parameter names, misplaced or multiple catch-alls, invalid method/ID and duplicate route IDs under the approved grammar.
- AC2. Errors identify route ID or registration position and a specific reason.
- AC3. Tests include valid/invalid patterns and boundaries at configuration limits.

### US-018 — Detect equal-priority overlaps
**As a** developer, **I want** conflicting routes rejected before startup **so that** routing is unambiguous by construction.

**Acceptance criteria**
- AC1. Detect overlapping route patterns for the same applicable method and equal priority, including literal-vs-param and catch-all intersections.
- AC2. Reject conflicting tables with a structured error naming both routes and conflicting priority.
- AC3. Higher-priority overlaps are allowed and produce one winner under the approved semantics.
- AC4. Verus establishes the table well-formedness invariant used by P3.

### US-019 — Freeze the compiled route table
**As a** server integrator, **I want** an immutable compiled table **so that** concurrent requests can share it safely without verified mutation logic.

**Acceptance criteria**
- AC1. Successful compilation returns a read-only table; no public mutator can change it after compilation.
- AC2. It can be shared through read-only Rust ownership (`Arc<CompiledTable>` or equivalent).
- AC3. Configuration updates require building a new table and restarting V1; no hot reload is exposed.

### US-020 — Validate handler registration completeness
**As a** server integrator, **I want** every route ID mapped to a handler at startup **so that** a verified decision cannot reference an absent handler silently.

**Acceptance criteria**
- AC1. Startup checks that every compiled route ID maps to exactly one available dispatcher entry.
- AC2. Missing/duplicate handler assignments return detailed startup errors.
- AC3. Dispatch mapping is immutable during request handling.

### US-021 — Prove table compilation and its bounds
**As a** reviewer, **I want** proof that every accepted table satisfies its invariants **so that** matching can rely on them safely.

**Acceptance criteria**
- AC1. Verus proves the accepted compiled-table invariant, including overlap/priority requirements and relevant size bounds.
- AC2. Compilation rejects route-count/pattern-length/segment-count limit violations without panic or overflow.
- AC3. All assumptions about input syntax and allowed methods are explicit in verification artifacts.

**E04 Definition of Done:** Compiled tables are immutable, syntactically valid, handler-complete and verified to satisfy P3 prerequisites and configuration limits.

---

## E05 — K4: Verified linear route matching and decisions
**Aligned phase:** 3  
**Epic outcome:** A deterministic synchronous matcher returns the correct route ID/parameters or typed rejection, with P1, P2, P3, P5, P6 and P8 evidence.

### US-022 — Implement linear method/path matcher
**As a** request processor, **I want** a linear route scan **so that** the simplest reference-compatible implementation can ship first.

**Acceptance criteria**
- AC1. Matcher accepts only a compiled table and validated canonical request representation.
- AC2. It considers method, literal/parameter/catch-all segment matching and explicit priorities.
- AC3. It returns the uniquely highest-priority match or a typed no-match decision.

### US-023 — Implement precise parameter capture
**As an** application handler, **I want** route captures **so that** handler inputs reflect the actual canonical URL.

**Acceptance criteria**
- AC1. Each `:param` captures exactly one segment at its position; a terminal catch-all captures zero or more remaining segments.
- AC2. Parameter names and values preserve the approved canonical representation, including trailing-slash semantics.
- AC3. Reconstructing the canonical path from pattern plus captured values yields the matched path (P6).

### US-024 — Distinguish 404, 405, HEAD and OPTIONS
**As an** HTTP application, **I want** explicit method behavior **so that** routing decisions can be converted into appropriate responses.

**Acceptance criteria**
- AC1. No matching canonical path produces `NotFound`; path matches with no permitted method produce `MethodNotAllowed` with allowed methods.
- AC2. An explicit HEAD route takes precedence; otherwise HEAD may reuse GET routing, while the response layer suppresses the response body.
- AC3. OPTIONS returns the allowed methods according to the approved specification; special precedence and unknown-path behavior are covered by tests.
- AC4. Method lists are deterministic and don't contain unapproved duplicates.

### US-025 — Prove refinement and priority correctness
**As a** reviewer, **I want** the executable matcher proved equivalent to `match_spec` **so that** matching behavior is mathematically justified.

**Acceptance criteria**
- AC1. Verus proves P2 for all tables satisfying the formal well-formedness predicate and all valid canonical requests in scope.
- AC2. Verus establishes P3 or invokes the verified P3 table invariant to prove the selected highest-priority result is unique.
- AC3. Proof covers both a successful route and each relevant rejection class; unsupported assumptions are documented.

### US-026 — Prove prefix confinement and parameter soundness
**As a** security reviewer, **I want** prefix and capture properties formally established **so that** routing cannot cross declared canonical prefix boundaries.

**Acceptance criteria**
- AC1. Verus proves P5 for prefix-mounted patterns under the defined segment-prefix relation.
- AC2. Verus proves P6 for normal parameters and terminal catch-all captures, including zero-segment matches.
- AC3. Adversarial examples cover dot segments, encoded dots, similar-looking prefixes (`/api/users2`), and trailing slash variants.

### US-027 — Prove bounded, panic-free matching
**As a** security reviewer, **I want** termination and work bounds **so that** the matcher does not loop forever or overflow under allowed inputs.

**Acceptance criteria**
- AC1. Verus proves totality/panic-freedom for the matcher's stated domain (P1).
- AC2. Loop invariants and arithmetic bounds establish finite work consistent with P8's explicit route and segment limits.
- AC3. Unit/regression tests cover empty tables, maximal valid inputs and limit rejection.

**E05 Definition of Done:** The linear matcher passes all P1/P2/P3/P5/P6/P8 proof obligations and all route-behavior acceptance tests.

---

## E06 — K1: Verified HTTP/3 pseudo-header validator
**Aligned phase:** 4  
**Epic outcome:** The kernel detects malformed decoded request-header lists under a reviewed RFC-based policy.

### US-028 — Define exact ordered-header input contract
**As a** kernel implementer, **I want** a byte-oriented ordered header-list contract **so that** the validator can detect conditions an early map conversion would destroy.

**Acceptance criteria**
- AC1. The K1 input format preserves every decoded name/value pair in its original order, including duplicates.
- AC2. The contract documents which header framing constraints are already handled by TQUIC and which are independently verified by K1.
- AC3. Bounds on header count and name/value lengths are represented and validated.

### US-029 — Validate ordinary request pseudo-headers
**As a** server, **I want** to reject malformed ordinary HTTP/3 header lists **so that** ambiguous requests are not routed.

**Acceptance criteria**
- AC1. For in-scope ordinary requests, enforce applicable uniqueness, presence and pseudo-before-regular ordering requirements, including `:method`, `:scheme`, `:path` and authority/Host semantics as approved from RFC 9114/9110.
- AC2. Duplicate required pseudo-headers, missing mandatory fields, invalid ordering and prohibited field forms yield distinct typed validation failures.
- AC3. Tests include both valid and invalid header sequences and authority/Host boundary cases.

### US-030 — Safely recognize unsupported CONNECT forms
**As a** kernel, **I want** to recognize CONNECT without tunneling **so that** special requests are safely rejected rather than misinterpreted.

**Acceptance criteria**
- AC1. Valid CONNECT and extended CONNECT formats recognized by the approved subset yield `UnsupportedConnect` or the specified unsupported outcome.
- AC2. Malformed CONNECT headers remain distinguishable from valid-but-unsupported requests.
- AC3. No CONNECT request is dispatched to an ordinary path route.

### US-031 — Expose typed validation results
**As an** adapter, **I want** structured reasons for header failures **so that** HTTP/3-compliant error handling is possible.

**Acceptance criteria**
- AC1. Validator returns a structured successful request/header interpretation or a specific error variant.
- AC2. Error variant mapping is documented for malformed-message stream errors vs ordinary HTTP-level unsupported decisions.
- AC3. The kernel does not directly perform async network writes or synthesize a misleading universal HTTP 400 response.

### US-032 — Verify P7 and validator safety
**As a** reviewer, **I want** a proof of header well-formedness checking **so that** the validator cannot accidentally accept disallowed ordered lists in its specified domain.

**Acceptance criteria**
- AC1. Verus proves P7 as defined by the approved applicable-header specification.
- AC2. Verus proves relevant P1/P8 properties for header traversal, bounds, and termination.
- AC3. Specification/review documentation explicitly avoids claiming full HTTP/3 protocol conformance solely from K1.

### US-033 — Exercise header adversarial corpus
**As a** tester, **I want** malformed header cases retained **so that** regressions are detected.

**Acceptance criteria**
- AC1. Corpus covers duplicates, pseudo-after-regular, missing required fields, oversized lists, invalid names, conflicting authority and CONNECT variations.
- AC2. Each corpus item has an expected kernel result and integration-level outcome.
- AC3. Automated test suite reproduces those outcomes with no unexpected panic.

**E06 Definition of Done:** K1 validates supported header semantics, proves P7/P1/P8 within its boundary, and passes adversarial tests.

---

## E07 — TQUIC adapter, dispatch and live HTTP/3 demo
**Aligned phase:** 5  
**Epic outcome:** Real HTTP/3 request headers pass losslessly to the verified kernel and accepted routes invoke mapped async handlers.

### US-034 — Implement a thin lossless TQUIC adapter
**As a** server integrator, **I want** a minimal adapter **so that** TQUIC header data reaches K1 without interpretive changes.

**Acceptance criteria**
- AC1. Adapter preserves header order, duplicates, name/value bytes and their exact decoded values as supplied by TQUIC.
- AC2. Adapter does not perform a second URL decoding pass, reorder fields, remove duplicates or select handlers.
- AC3. Its assumptions and line-level responsibilities are documented; size remains small and code is independently reviewable (the draft targets roughly <150 LoC, not a hard functional cap).

### US-035 — Build immutable route-ID dispatch
**As an** application integrator, **I want** to map kernel route IDs to async Rust handlers **so that** verified route selection can drive real responses.

**Acceptance criteria**
- AC1. Mapping is initialized and validated before serving traffic; no runtime mutations are exposed.
- AC2. Successful decision dispatches exactly the mapped handler with the captured parameter data.
- AC3. Missing handler mapping cannot be ignored or silently replaced with another handler.

### US-036 — Implement response and stream-error mapping
**As an** HTTP/3 client, **I want** appropriate outcomes for accepted and rejected requests **so that** protocol behavior is predictable.

**Acceptance criteria**
- AC1. A valid matched request receives the demo handler's expected HTTP/3 response.
- AC2. No-path, method-not-allowed, HEAD and OPTIONS decisions map to responses with correct body and method-header behavior.
- AC3. Malformed HTTP/3 messages follow the applicable stream-error behavior rather than always being converted into an HTTP 400 response.
- AC4. Unsupported CONNECT is rejected safely and does not open a tunnel.

### US-037 — Provide end-to-end demonstration routes
**As a** reviewer, **I want** a runnable demo **so that** the entire architecture can be evaluated without writing another application.

**Acceptance criteria**
- AC1. Demo includes literal, `:param` and catch-all endpoints and both GET/POST examples.
- AC2. README supplies exact server startup and HTTP/3 client commands showing route ID/param correctness.
- AC3. Demonstration covers a valid route, 404, 405, HEAD, OPTIONS, malformed path and malformed headers.

### US-038 — Run HTTP/3 interoperability tests
**As a** tester, **I want** standard HTTP/3 compatibility checks **so that** integration errors are not disguised as router problems.

**Acceptance criteria**
- AC1. A documented HTTP/3 interoperability suite or `h3spec` equivalent runs against the server with pinned configuration.
- AC2. All scenarios applicable to the declared scope pass; intentionally unsupported features are recorded, not silently counted as passes.
- AC3. Logs preserve test command, test version, results and relevant traces.

### US-039 — Independently review and fuzz the adapter
**As a** security reviewer, **I want** targeted adapter assurance **so that** unverified translation cannot silently erase malformed-request evidence.

**Acceptance criteria**
- AC1. Reviewer other than author audits duplicate/order preservation, lifetimes, bounds and error translation.
- AC2. `cargo-fuzz` or equivalent explores raw ordered header lists, including duplicates and malformed values; crashes or semantic discrepancies are fixed or tracked as release blockers.
- AC3. Audit report and fuzz seeds/corpus are included in verification evidence.

**E07 Definition of Done:** Runnable HTTP/3 server demonstrates routing through the verified kernel; adapter audit, fuzzing and applicable interop tests pass.

---

## E08 — Verification-aware security and regression testing
**Aligned phases:** 2–5  
**Epic outcome:** Automated testing challenges both the implementation and the adequacy of its specifications.

### US-040 — Maintain deterministic regression corpus
**As a** maintainer, **I want** a permanent security corpus **so that** fixed bugs stay fixed.

**Acceptance criteria**
- AC1. Corpus includes encoded dots, double encoding, encoded slashes, backslashes, rootless request targets, overlong/invalid UTF-8, traversal and size boundaries.
- AC2. Every test case states the expected typed decision under the approved specification.
- AC3. CI runs the fast corpus on each pull request.

### US-041 — Implement comparative routing tests
**As a** tester, **I want** randomized comparison against a reference router **so that** disagreements reveal possible semantic bugs.

**Acceptance criteria**
- AC1. Generate random valid route tables and request paths on a documented comparable subset.
- AC2. Compare route identity and captures using an explicit mapping of the reference router's rules to ours.
- AC3. Every disagreement is classified as a router bug, spec issue, reference difference, or unresolved issue; unresolved critical mismatches block release.

### US-042 — Add proof mutation tests
**As a** verifier, **I want** deliberately faulty variants rejected by Verus **so that** proofs meaningfully constrain executable behavior.

**Acceptance criteria**
- AC1. Mutations target path canonicalization, route selection, priority handling and parameter extraction.
- AC2. Each selected mutant that violates an approved property causes verification to fail; equivalent/nonviolating mutations are classified explicitly.
- AC3. Evidence records original and mutated behavior, verifier output and classification.

### US-043 — Enforce fast PR checks and longer release checks
**As a** maintainer, **I want** proportional CI coverage **so that** normal changes stay efficient while releases remain rigorous.

**Acceptance criteria**
- AC1. PR CI runs formatting/static checks, build, unit tests, Verus verification, fast integration/regression tests and TCB exemption checks.
- AC2. Release gate adds longer fuzzing, mutation suite, interoperability and full benchmark evidence.
- AC3. Required checks are blocking; logs and failure diagnostics are retained.

### US-044 — Track failures and triage evidence
**As a** project owner, **I want** every material failure classified **so that** a green proof dashboard cannot conceal known weaknesses.

**Acceptance criteria**
- AC1. Test failures, fuzz crashes, proof failures and differential mismatches have severity, reproduction steps, owner and resolution.
- AC2. All security-critical or correctness-critical unresolved issues block release.
- AC3. Deliberate behavior differences are linked to corresponding specification clauses.

**E08 Definition of Done:** All fast and release security checks pass; evidence is reproducible and no unresolved critical issue remains.

---

## E09 — Performance validation and optional optimization
**Aligned phases:** 5, optional 6  
**Epic outcome:** Verified routing performance is measured reproducibly and satisfies an agreed p99 budget.

### US-045 — Establish reproducible baseline workloads
**As a** performance reviewer, **I want** representative route tables and requests **so that** router comparisons are meaningful.

**Acceptance criteria**
- AC1. Workloads include small/medium/large route tables, literal, parameter and catch-all matches, no-match requests and bounded adversarial cases.
- AC2. Baseline and verified router use equivalent operations, machine configuration and measurement method.
- AC3. Results record code revision, dependency versions, warmup, repetitions and workload dataset.

### US-046 — Measure route latency and throughput
**As a** project owner, **I want** p50/p95/p99 and throughput measurements **so that** overhead is visible.

**Acceptance criteria**
- AC1. Benchmarks separately measure kernel routing time and, where practical, end-to-end HTTP/3 behavior without conflating network delays.
- AC2. Results include p50/p95/p99 latency, throughput, allocation/memory observations where available, and comparison against the chosen unverified baseline.
- AC3. A written methodology allows another engineer to reproduce the measurements.

### US-047 — Agree and enforce a performance budget
**As a** technical reviewer, **I want** a measurable p99 gate **so that** release acceptance is objective.

**Acceptance criteria**
- AC1. Numeric p99 overhead budget and applicable workload(s) are established after baseline results and signed off before release.
- AC2. V1 passes the agreed budget, or a failed gate triggers an explicit scope/performance decision rather than an undocumented exception.
- AC3. Benchmark report includes the pass/fail computation and supporting raw results.

### US-048 — Evaluate optional Trie optimization (Conditional)
**As a** maintainer, **I want** optimization only when measurements justify it **so that** proof complexity is not increased unnecessarily.

**Acceptance criteria**
- AC1. If the linear matcher meets the agreed budget, no Trie is required for V1 and the decision is documented.
- AC2. If an optimization is approved, trie matching must be proved equivalent to the same `match_spec`/flat-table semantics.
- AC3. An approved Trie must pass the same functional, security and regression suites and demonstrate a measurable benefit.

**E09 Definition of Done:** Benchmarks are reproducible, the approved p99 gate passes, and the optional Trie decision is documented.

---

## E10 — Assurance, documentation and final acceptance
**Aligned phases:** 0–5  
**Epic outcome:** A reviewer can independently rebuild, verify, run, evaluate and approve the engineering artifact.

### US-049 — Maintain trusted computing base registry
**As a** security reviewer, **I want** `TCB.md` **so that** verification limitations are not concealed.

**Acceptance criteria**
- AC1. `TCB.md` identifies TQUIC/QUIC/TLS/QPACK, adapter, dispatch/handlers, Rust compiler, Verus, Z3, and all trusted external declarations/assumptions.
- AC2. Every `external_body`, `assume_specification` and explicit `assume` has rationale, owner and review record where applicable.
- AC3. CI detects new unregistered exemptions and fails until `TCB.md` and review record are updated.

### US-050 — Publish verification evidence report
**As a** project owner, **I want** a P1–P8 evidence report **so that** each claim can be reviewed independently.

**Acceptance criteria**
- AC1. Report maps each P-property to approved statement, relevant source, proof command, passing logs and assumptions.
- AC2. It distinguishes which production code paths are verified and which interfaces remain unverified.
- AC3. Evidence includes independent specification approval and version-pinned verification outputs.

### US-051 — Document public API and usage
**As a** Rust developer, **I want** usable documentation **so that** the crate can be adopted without knowledge of the research plan.

**Acceptance criteria**
- AC1. README explains installation/build, route builder, priority, catch-all, errors, HEAD/OPTIONS and demo usage.
- AC2. Architecture diagram shows trust boundary, request flow, typed decisions and dispatch.
- AC3. Public API examples compile and are covered by tests.

### US-052 — Deliver complete review package
**As a** boss/reviewer, **I want** all code and evidence together **so that** the project can be evaluated and maintained.

**Acceptance criteria**
- AC1. Repository contains source crates, Verus specs/proofs, HTTP/3 demo, tests, fuzz harnesses, regression corpus, benchmark data/scripts, CI and documentation.
- AC2. A clean checkout can run the documented build, proof, test and demo commands successfully.
- AC3. Release notes list supported features, known exclusions and compatibility constraints.

### US-053 — Obtain evidence-based technical sign-off
**As a** project owner, **I want** formal acceptance against defined gates **so that** the deliverable is not called complete prematurely.

**Acceptance criteria**
- AC1. Approved P1–P8 proofs pass against the shipped implementation; no proof obligation remains silently deferred.
- AC2. TQUIC example, adapter audit, fuzz/security/mutation/interop tests, and p99 budget all pass with recorded evidence.
- AC3. Reviewer confirms independent spec sign-off, complete `TCB.md`, documented assumptions, and no critical blockers.
- AC4. Release checklist records approver, date, exact commit and final accepted artifact version.

**E10 Definition of Done:** Independent reviewer reproduces and signs off on the complete, verified V1 artifact and its evidence.

---

## 7. Phase plan, dependencies and gates

| Boss's phase | Primary epics | Required output | Gate to proceed |
|---|---|---|---|
| **0 — Spike** | E01 | Toolchain, CI proof smoke test, HTTP/3 header-event demo | CI rejects proof failures; demo works |
| **1 — Specs** | E02 | Reviewed English + Verus specs, examples, P1–P8 map | Independent spec sign-off |
| **2 — K2 canonicalizer** | E03 + E08 | Verified normalization; security tests; differential fuzzing | Proofs pass; 24h campaign has zero unresolved mismatches |
| **3 — K3 + K4 linear router** | E04 + E05 + E08 | Verified immutable table, priorities, matcher/captures | P2/P3/P5/P6/P8 and applicable P1 proof obligations pass; mutants fail verification |
| **4 — K1 header validator** | E06 | Verified header rules and typed rejections | P7 and applicable safety proofs pass; interop/header tests pass |
| **5 — Integration/benchmarks** | E07 + E08 + E09 + E10 | TQUIC routing demo, audited adapter, p99 benchmark, release package | Full P1–P8, security, interop, performance, evidence and sign-off |
| **6 — Optional Trie** | E09/US-048 | Optimized matcher + refinement proof | Only after justified by performance and separately approved |

**Delivery order note:** E08 and E10 evidence work runs continuously alongside feature phases; it is not postponed to the end.

---

## 8. Story-to-proof traceability

| Property | Verification-bearing stories | Supporting evidence |
|---|---|---|
| P1 | US-011, US-014, US-021, US-027, US-032 | Totality/panic/overflow proofs, boundary tests |
| P2 | US-007, US-022, US-025 | `match_exec` refines `match_spec` |
| P3 | US-018, US-021, US-025 | Table well-formedness and unique winner proof |
| P4 | US-012, US-013, US-014 | Canonicalization refinement + idempotence proof |
| P5 | US-013, US-026 | Segment-prefix confinement proof |
| P6 | US-023, US-026 | Exact capture and reconstruction proof |
| P7 | US-028, US-029, US-032 | Ordered pseudo-header validity proof |
| P8 | US-011, US-021, US-027, US-032 | Verified bounds/termination + limit tests |

---

## 9. Global Definition of Done

A story is **Done** only when its implementation, tests, proof obligations (if relevant), documentation and required reviews are committed and CI passes. An epic is **Done** only when all its mandatory stories meet their criteria and its epic gate is satisfied.

The **V1 product is accepted only when all** of the following hold:

1. **Scope complete:** Q1–Q30 decisions implemented, with any approved amendments documented; optional Trie excluded unless justified.
2. **Formal guarantees:** The shipped routing kernel has passing, reviewable machine-checked proofs of P1–P8 under explicitly documented assumptions.
3. **Specification reviewed:** Reviewer other than author approves English and mathematical definitions, especially URL and RFC semantics.
4. **HTTP/3 operational:** TQUIC demo processes genuine HTTP/3 requests and correctly handles valid routes, rejections, HEAD/OPTIONS and unsupported CONNECT.
5. **Security evidence:** Canonicalizer, route table, matcher and header validator pass required fuzz, differential, mutation and regression campaigns; no unresolved security-critical defect.
6. **Unverified boundary audited:** Thin adapter has independent review and fuzz results; TCB registry covers all trusted assumptions and exclusions; CI enforces it.
7. **Performance accepted:** Reproducible baseline exists, numeric p99 overhead budget is formally agreed, and V1 meets it.
8. **Reproducible handoff:** Pinned dependencies, clean-build documentation, verifier logs, CI status, example requests, benchmark evidence and release notes are included.
9. **Sign-off:** Technical reviewer approves the exact release commit/version; all outstanding deviations are either closed or explicitly accepted as nonblocking with rationale.

**No claim of full-server formal verification is permitted.** Release messaging must distinguish proved synchronous-kernel properties from audited/tested-but-unverified networking and handlers.

---

## 10. Risks and mitigations

| Risk | Mitigation / requirement |
|---|---|
| Specification precisely proves the wrong URL semantics | Independent Phase-1 review, adversarial proof examples, differential testing |
| Double decoding causes downstream path reinterpretation | One canonical representation, no downstream decoding, explicit residual-escape policy |
| Unverified TQUIC/adapter bugs invalidate end-to-end assurances | Thin lossless adapter, TCB register, independent audit and fuzz testing |
| Verus/Rust upgrades break proofs | Exact dependency pinning, intentional upgrade process with full CI |
| Linear matcher misses latency budget | Baseline and p99 gate; optional approved Trie with refinement proof |
| Scope expands into async handlers or full protocol verification | Hard synchronous verification boundary; separate dispatch layer |
| Too many assumptions make verification vacuous | CI registry for trusted exemptions, proof traceability, independent review |
| Catch-all and trailing-slash semantics conflict | Canonical capture/reconstruction examples and formal review before implementation |

---

## 11. Suggested repository structure (non-normative)

```text
verified-http3-router/
├── crates/
│   ├── verified-router/       # K1–K4 implementation + Verus code
│   └── tquic-adapter/         # thin, audited integration
├── examples/
│   └── http3-server/         # real TQUIC demo + async dispatch
├── tests/
│   ├── regression/
│   ├── differential/
│   ├── fuzz/
│   └── integration/
├── benchmarks/
├── docs/
│   ├── architecture.md
│   ├── formal-specification.md
│   ├── specification-review.md
│   ├── verification-report.md
│   └── benchmark-report.md
├── TCB.md
├── Cargo.lock
├── rust-toolchain.toml
├── README.md
└── .github/workflows/
```

## 12. Source and standards references

- Boss's draft: *Plan: A Verus-Verified Request Router on TQUIC (HTTP/3)*, dated 23 November 2026 (primary architecture, scope, P1–P8 and phases).
- Verus guide: https://verus-lang.github.io/verus/guide/
- Verus supported Rust features: https://verus-lang.github.io/verus/guide/features.html
- HTTP/3 — RFC 9114: https://www.rfc-editor.org/rfc/rfc9114.html
- HTTP Semantics — RFC 9110: https://www.rfc-editor.org/rfc/rfc9110.html
- URI Syntax — RFC 3986: https://www.rfc-editor.org/rfc/rfc3986.html
- TQUIC: https://github.com/Tencent/tquic
- `matchit` reference router: https://docs.rs/matchit/latest/matchit/
- Rust Fuzz Book: https://rust-fuzz.github.io/book/

---

**Approval status:** Q1–Q30 product choices confirmed by project implementer. Technical review of the exact formal specifications, unresolved low-level semantics, performance budget and release evidence is **pending**. This PRD must not be mistaken for proof completion or boss's formal sign-off.
