# Plan: A Verus-Verified Request Router on TQUIC (HTTP/3)

*Status: draft plan, 23 Nov 2026. Literature survey current as of that date.*

**How to read this document.** Statements of fact carry a reference like [R3]. Sentences marked **Recommendation**, **Judgment** or **Estimate** are my own reasoning, not sourced fact. Anything marked *(from memory, unverified)* was not checked against a source in this research pass.

---

## 1. Summary

- **Finding.** I found no published, production-grade HTTP router in Rust with Verus-verified route matching. The closest work verifies *parsing* (HTTP/1.1 heads, binary formats, X.509), not the routing decision itself [R10][R11][R7].
- **Judgment.** That gap is a good opportunity. Route matching is small, pure and deterministic, which is the kind of code Verus handles well. It is also security-relevant: path confusion has caused real routing bypasses, such as the 2026 Traefik advisory, where a rootless request-target was routed as `/` but forwarded verbatim [R17].
- **Recommendation.** Don't verify TQUIC. Build a **verified routing kernel**: a synchronous, allocation-light Verus crate that takes the HTTP/3 pseudo-headers TQUIC gives you and returns a route ID and captured parameters, or a typed rejection. All async I/O stays in unverified code, which is required anyway because Verus does not support `async`/`await` [R14].

---

## 2. State of the art (what exists, Nov 2026)

### 2.1 Verus itself
| Work | What it shows | Ref |
|---|---|---|
| Verus (OOPSLA 2023) | SMT-based verifier for Rust; specs and proofs are written in Rust syntax and exploit linear ghost types | [R1] |
| Verus (SOSP 2024) | Case studies covering 6.1K lines of implementation and 31K lines of proof (including distributed systems, an OS page table, a crash-safe storage system and a concurrent memory allocator); verifies 3 to 61x faster than prior state of the art | [R2] |
| FMCAD 2026 tutorial | Verus is reported in industrial use at Microsoft and Amazon | [R3] |

### 2.2 Systems verified with Verus (closest analogues)
| Work | Relevance to a router | Ref |
|---|---|---|
| **Vest** (USENIX Sec 2025) | Verified zero-copy *binary* parser/serializer combinators. Proves no out-of-bounds access, no overflow, termination, panic-freedom, and round-trip/non-malleability. Case studies: Bitcoin blocks, TLS 1.3 handshake, WebAssembly | [R4][R5] |
| **Verdict** (USENIX Sec 2025) | End-to-end verified X.509 validator in Rust/Verus. Its *policy compiler* pattern (spec in logic, generated proved code) is the model I propose for route tables | [R6][R7] |
| **Anvil** (OSDI 2024, Best Paper) | Liveness verification of Kubernetes controllers. Shows how to wrap unverified external crates (`kube`) around a verified core | [R8] |
| **Atmosphere** (SOSP 2025) | Verified kernel; proof-to-code ratio about 3.32:1, verification under 20 s on a laptop | [R9] |

### 2.3 HTTP-facing Verus work (small, early)
| Work | What is verified | Maturity | Ref |
|---|---|---|---|
| **httpd-rs** | Percent-decoding, path canonicalization, HTTP/1.1 request-head parsing and body framing | 3 stars; author says security claims are self-assessed | [R10] |
| **asagiri PR #83** | Content-Length and chunk-size parsers. Notable practice: *all six parser mutants fail proof verification* | Single PR, Nov 2026 | [R11] |

Neither one covers HTTP/3 or route matching [R10].

### 2.4 QUIC and HTTP/3 assurance
| Work | Method | Ref |
|---|---|---|
| **EverQuic** (IEEE S&P 2021) | F*/Low*: QUIC record layer proven memory-safe, functionally correct and secure; full QUIC within 21% of an unverified baseline | [R12] |
| **Ivy QUIC spec** (McMillan & Zuck) | Formal spec used to *generate randomized testers*; found real implementation bugs | [R13] |
| **TQUIC** | States it "has been verified by formal specification using the Ivy tool" and passed IETF interop tests | [R15] |

**Judgment.** TQUIC's Ivy claim means specification-based testing, which is what [R13] describes. It is not a proof. Your trusted computing base therefore includes all of TQUIC, including QPACK decoding.

### 2.5 LLM-assisted proof (relevant to effort)
| Work | Result | Ref |
|---|---|---|
| **AutoVerus** (OOPSLA, Distinguished Artifact) | Proved more than 90% of 150 small benchmark tasks | [R18] |
| **VeruSAGE** (2025/26) | 849 *system-level* tasks; best LLM+agent combination proves over 80%, about 7.2 min per task | [R19] |
| **VeruSyn** (2026) | Synthesized 6.9M verified Verus programs as training data | [R20] |

**Judgment.** Proof effort for a router kernel is now much lower than SOSP-era numbers suggest, *provided the specs are written and reviewed by a human*. LLMs help prove a spec. They can't tell you the spec is the right one.

---

## 3. Constraints that shape the design

1. **No async in Verus.** Async functions, async blocks and `.await` are all "Not supported" [R14]. *So the kernel must be synchronous and pure.*
2. **Partial support** for trait objects (`dyn`), iterators, `for` loops and closures with mutable captures [R14]. *So the kernel uses index loops and returns a route ID (an integer or enum), not a `Box<dyn Handler>`.*
3. **Supported:** `&str`, `String`, `Vec`, `HashMap`, slices [R14]. *So a segment-based route table is expressible.*
4. **TQUIC's h3 API is event-driven**: it exposes an `Http3Event` enum, including a `Headers` event carrying header fields [R16]. *So it fits cleanly: on a `Headers` event, hand the header list to the kernel.*

---

## 4. Architecture

```
 UDP ──► TQUIC (QUIC + TLS + QPACK + h3)        [unverified, Ivy-tested]
            │ Http3Event::Headers { headers, .. }
            ▼
     Adapter (thin, unverified, < ~150 LoC)      [audited + fuzzed]
            │ &[(&[u8], &[u8])]   (name, value) pairs
            ▼
 ┌──────────── verified kernel (Verus) ─────────────┐
 │ K1 pseudo-header validation  (:method :scheme     │
 │    :authority :path, RFC 9114 rules)              │
 │ K2 path decode + canonicalize (percent-decoding,  │
 │    dot-segment removal, reject encoded '/', NUL)  │
 │ K3 route table: compile + well-formedness check   │
 │ K4 match: (method, authority, segments) → Decision│
 └───────────────────────────────────────────────────┘
            │ Decision::Route{id, params} | Reject{status}
            ▼
     Dispatch table: id → async handler          [unverified]
```

**Recommendation.** The route table is built at startup from a declarative config, checked by K3, and then frozen and immutable. That avoids concurrency proofs entirely. Use `Arc<CompiledTable>` shared read-only across connections.

---

## 5. What to prove (the specification)

Each property is written first as a Verus `spec fn` and then proved about the `exec fn`.

| # | Property | Kind |
|---|---|---|
| P1 | **Totality / panic-freedom**: for every input byte sequence, the kernel returns a `Decision` and never panics or overflows | Safety |
| P2 | **Functional correctness**: `match_exec(t, req) == match_spec(t@, req@)`, where `match_spec` is a simple, obviously correct linear scan over routes | Refinement |
| P3 | **Determinism / no ambiguity**: K3 accepts a table only if no request can match two routes at the same priority. Alternative: priority is a total order and P2 returns the unique maximum | Table invariant |
| P4 | **Canonical-path containment**: after K2, the path contains no `.` or `..` segments, no empty interior segments, and no decoded `/` inside a segment. Canonicalization is idempotent: `canon(canon(p)) == canon(p)` | Security |
| P5 | **Prefix confinement**: if a route is mounted under prefix `/a/b`, every request it receives has a canonical path starting with segments `a`, `b` | Security |
| P6 | **Parameter soundness**: captured params are exactly the request segments at the wildcard positions, so reassembling pattern + params yields the canonical path | Correctness |
| P7 | **Pseudo-header well-formedness**: exactly one each of `:method`, `:scheme`, `:path` (and `:authority` or `host`), no duplicates, pseudo-headers before regular headers *(RFC 9114 rules from memory, unverified: check §4.3.1 when writing the spec)* | Conformance |
| P8 | **Bounded work**: matching cost is at most `O(|segments| × |routes|)` for the linear version, or `O(|path|)` for the trie, with explicit caps on segment count and length | DoS |

**Spec sketch** (illustrative and not yet compiled):

```rust
verus! {
pub enum Seg { Lit(Seq<u8>), Param, CatchAll }
pub struct Route { method: Method, pattern: Seq<Seg>, priority: u32, id: u32 }

pub open spec fn seg_matches(p: Seq<Seg>, s: Seq<Seq<u8>>) -> bool
    decreases p.len()
{
    if p.len() == 0 { s.len() == 0 }
    else match p[0] {
        Seg::CatchAll => p.len() == 1,                         // must be last
        Seg::Param    => s.len() > 0 && seg_matches(p.drop_first(), s.drop_first()),
        Seg::Lit(l)   => s.len() > 0 && s[0] == l
                          && seg_matches(p.drop_first(), s.drop_first()),
    }
}

pub open spec fn match_spec(t: Seq<Route>, m: Method, s: Seq<Seq<u8>>) -> Option<u32> {
    // highest-priority route whose method and pattern match; None => 404/405
}

pub fn route(t: &CompiledTable, req: &Request) -> (d: Decision)
    requires t.wf(),
    ensures  d.refines(match_spec(t@, req.method@, canon(req.path@))),
{ ... }
}
```

---

## 6. Data-structure strategy

**Recommendation: two stages, with a refinement proof between them.**

1. **Stage A, linear table.** `Vec<Route>`, sorted by priority, scanned in a loop. The proof is nearly trivial against `match_spec`. Ship this first, since it is likely fast enough for tables up to a few hundred routes *(Estimate)*.
2. **Stage B, segment trie.** A trie keyed by literal segments, with param/catch-all children, like the radix tree in Go's `httprouter` [R21]. Prove `trie_match(t) == match_spec(flatten(t))`. Stage A's spec stays the source of truth, so the fast path never changes meaning.

**Judgment.** Avoid regex routes in the verified kernel. A verified regex engine is a separate research project. Treat regex routes as an unverified extension point, or leave them out.

---

## 7. Phased plan

| Phase | Deliverable | Exit criterion |
|---|---|---|
| **0. Spike** (1 to 2 wk) | Verus toolchain pinned; hello-world `cargo verus verify` in CI; TQUIC h3 server receiving `Headers` events | CI fails on any proof error |
| **1. Specs only** | `spec fn`s for P2 to P7 plus a written English rationale; spec reviewed by someone other than the author | Spec review sign-off; spec unit tests (`proof fn` examples on concrete paths like `/a/../b`, `/%2e%2e/`, `//x`) |
| **2. K2 canonicalizer** | Exec percent-decode + dot-segment removal proved against spec (P1, P4) | Proof passes; differential fuzz against a reference implementation, zero mismatches over 24 h |
| **3. K3 + K4 linear router** | Table compiler with well-formedness (P3) and linear matcher (P2, P5, P6, P8) | Proof passes; mutation test: every injected mutant fails proof (the asagiri practice [R11]) |
| **4. K1 pseudo-headers** | Validator for TQUIC header lists (P7) | Proof passes; h3spec/interop runs clean |
| **5. Integration** | Adapter + dispatch on TQUIC; benchmarks vs an unverified baseline router | p99 routing overhead within agreed budget; adapter audited |
| **6. Trie (optional)** | Stage B with refinement proof | Same tests as phase 3, plus performance gain shown |

**Estimate (low confidence):** phases 0 to 5 take one experienced Rust engineer, new to Verus, about 6 to 10 weeks with LLM proof assistance in the AutoVerus/VeruSAGE style. Most of the time goes into the specs, not the proofs.

---

## 8. Trusted computing base (be explicit)

What the proofs do **not** cover:

- TQUIC: QUIC, TLS, **QPACK decoding**, stream handling (Ivy-tested, not proved) [R15][R13]
- The adapter between TQUIC's header list and the kernel's input type
- Verus itself, Z3, `rustc`, and any `#[verifier::external_body]` or `assume_specification` you write
- The **specs** (a wrong spec gives a proved wrong router)
- Handlers, and anything after `Decision` is returned

**Recommendation.** Keep a `TCB.md` file listing every `external_body` and `assume` and the reason for it. Have CI fail if that count grows without the file being updated.

---

## 9. Testing around the proofs

- **Differential testing.** Run the kernel against an established unverified router on random route tables and paths, for example `matchit` *(from memory, unverified: the router underneath axum)*. Treat each disagreement as either a bug in the spec or a deliberate, documented difference.
- **Fuzzing the adapter** with `cargo-fuzz` on raw header lists.
- **Mutation testing of proofs** (phase 3 exit criterion).
- **Regression corpus** of known path-confusion payloads: encoded dots, double encoding, backslashes, rootless request targets [R17], overlong UTF-8.

---

## 10. Risks and premortem

*"It is one year later and this failed. Why?"*

| Failure story | Mitigation |
|---|---|
| The spec encoded the wrong semantics (for example, `%2F` handling), so a proved router was still exploitable | Phase 1 spec review; differential testing; adversarial corpus |
| Proof maintenance stalled each Verus upgrade | Pin the Verus version (Anvil pins a commit [R8]); upgrade on a schedule |
| The real bug was in QPACK or the adapter, outside the proof | Document the TCB; fuzz the adapter; track TQUIC advisories |
| Verified router too slow, team bypassed it | Stage A benchmarks early; Stage B trie with refinement proof |
| Scope creep into verifying handlers or async | Hard boundary: the kernel is sync and pure, and returns an ID |

**Forecasts (Judgment, for later scoring):**
- 80%: Stage A (phases 0 to 3) is proved within 6 weeks.
- 60%: differential testing finds at least one spec-level disagreement worth fixing.
- 30%: you end up needing the Stage B trie for performance.

---

## 11. Open questions for you

1. Do you need host- or authority-based virtual hosting in the verified kernel, or only path routing?
2. What route syntax is required: literals, `:param` and `*catchall` only, or more (optional segments, regex)?
3. Should matching be case-sensitive, and how should trailing slashes be handled (redirect, strict, or ignore)? These must be fixed in the spec.
4. Is the route table static at startup, or must it be hot-reloadable? Hot reload is fine if each table is rebuilt and swapped atomically, still immutable.

---

## References

- [R1] Lattuada et al., *Verus: Verifying Rust Programs using Linear Ghost Types*, OOPSLA 2023. https://arxiv.org/pdf/2303.05491.pdf
- [R2] Lattuada et al., *Verus: A Practical Foundation for Systems Verification*, SOSP 2024. https://www.microsoft.com/en-us/research/publication/verus-a-practical-foundation-for-systems-verification/ ; artifact and case studies: https://verus-lang.github.io/paper-sosp24-artifact/case-studies
- [R3] Hance, *Verifying Rust code with Verus*, FMCAD 2026 tutorial. https://repositum.tuwien.at/handle/20.500.12708/230444
- [R4] Cai et al., *Vest: Verified, Secure, High-Performance Parsing and Serialization for Rust*, USENIX Security 2025. https://www.usenix.org/conference/usenixsecurity25/presentation/cai-yi
- [R5] Vest crate documentation. https://docs.rs/crate/vest/0.1.4
- [R6] Lin et al., *Towards Practical, End-to-End Formally Verified X.509 Certificate Validators with Verdict*, USENIX Security 2025. https://www.usenix.org/conference/usenixsecurity25/presentation/lin-zhengyao
- [R7] Verdict paper PDF. https://www.usenix.org/system/files/usenixsecurity25-lin-zhengyao.pdf
- [R8] Sun et al., *Anvil: Verifying Liveness of Cluster Management Controllers*, OSDI 2024. https://usenix.org/conference/osdi24/presentation/sun-xudong ; code: https://github.com/anvil-verifier/anvil
- [R9] Chen et al., *Atmosphere: Practical Verified Kernels with Rust and Verus*, SOSP 2025. https://mars-research.github.io/doc/2025-sosp-atmo.pdf
- [R10] httpd-rs (JD-P). https://github.com/JD-P/httpd-rs
- [R11] asagiri PR #83, *Verify production HTTP framing number parsing with Verus*. https://github.com/AndreKurait/asagiri/pull/83
- [R12] Delignat-Lavaud et al., *A Security Model and Fully Verified Implementation for the IETF QUIC Record Layer*, IEEE S&P 2021. https://www.normalesup.org/~ramanana/research/everest/everquic/paper.pdf ; code: https://github.com/project-everest/everquic-crypto
- [R13] McMillan & Zuck, *Formal specification and testing of QUIC*. https://par.nsf.gov/servlets/purl/10213951 ; see also Crochet et al., *Verifying QUIC implementations using Ivy*. https://arxiv.org/pdf/2503.01374
- [R14] Verus guide, *Supported Rust Features*. https://verus-lang.github.io/verus/guide/features.html
- [R15] TQUIC repository README. https://github.com/Tencent/tquic
- [R16] TQUIC 1.6.0 `src/h3/h3.rs`. https://docs.rs/crate/tquic/latest/source/src/h3/h3.rs
- [R17] GitHub Advisory GHSA-f52w-8j3h-j724 (Traefik, CVE-2026-88009). https://github.com/advisories/GHSA-f52w-8j3h-j724
- [R18] Yang et al., *AutoVerus: Automated Proof Generation for Rust Code*, OOPSLA. https://arxiv.org/abs/2409.13082
- [R19] Yang et al., *VeruSAGE: A Study of Agent-Based Verification for Rust Systems*. https://arxiv.org/abs/2512.18436
- [R20] *Reducing the Costs of Proof Synthesis on Rust Systems by Scaling Up a Seed Training Set* (VeruSyn). https://arxiv.org/pdf/2602.04910
- [R21] julienschmidt/httprouter (radix-tree router design). https://github.com/julienschmidt/httprouter
