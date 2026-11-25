# Trusted computing base (TCB) — skeleton, Phase 0 baseline

Status: draft. Phase 0 contains only workspace scaffolds, a standalone Verus smoke proof, and a
loopback TQUIC header demo; no kernel logic or P1–P8 proof exists yet. The exemption tables are
empty because no trusted declaration has been added, not because an audit has passed. Every
`external_body`, `assume_specification`, and explicit `assume` added later must be recorded here
with rationale, owner, and review record, or CI fails the change.

## Trusted components (unverified by this project)
- TQUIC, including QUIC, TLS, QPACK decoding, and HTTP/3 stream handling (Ivy-tested, not
  proved for our use).
- The thin TQUIC adapter between TQUIC header events and the kernel input type.
- Async route-ID-to-handler dispatch and all application handlers and responses.
- Toolchain: Rust compiler, Verus verifier, Z3 solver, pinned per Phase 0.
- The specifications themselves: a proved wrong spec still yields a wrong router, which is
  why E02 requires independent spec sign-off plus adversarial examples.

## Verified boundary
- Synchronous kernel only: K1 header validation, K2 canonicalization, K3 table validation,
  K4 linear matching. In V1, proofs are to cover P1–P8 on the shipped code path under
  documented assumptions. No full-server verification is claimed, and Phase 0 makes no
  P1–P8 claim.

## Proof exemptions (none yet — no trusted declarations added)
| Location | Kind | Rationale | Owner | Review |
|---|---|---|---|---|
| — | — | — | — | — |

Rules: no undocumented `assume`/`external_body`/`assume_specification`; no silent additions;
each entry needs owner plus review record; CI detects unregistered exemptions and blocks.
The count below is a tripwire, not evidence: exemptions: 0, all recorded: yes (vacuous).

## Assumptions log
| Date | Assumption | Scope | Status |
|---|---|---|---|
| 2026-11-24 | Launch-time shell constraint; no build/test/Verus claim at that moment | whole route | superseded by the Phase 0 evidence in `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0.md` |
| 2026-11-24 | Phase 0 local checks ran with repo-pinned tools; a clean Ubuntu 24.04 replay from a `git archive` of `e757847dfced9dab426e13f39d25d2a766033b16` passed with canonical sanitized-tree manifest `87721388b91464a82b4ef117ddf9a84935c09c18098d1d2498631015e2ebba70` (evidence: `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/clean-container-e757847-provenance.log` and `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/clean-container-e757847.manifest.txt`); the container had no `.git` and used the manifest label, not a Git revision; hosted workflow run 45646863052 on eedcc026b4b3c450fe247df95e812e620473ee82 succeeded and uploaded proof logs; independent GPT-6 Luna High `review-hosted-phase0-1.md` returned VERDICT: pass, no P0/P1 | whole route | closed: hosted CI and artifact independently verified |
