# Trusted computing base (TCB) — skeleton, Phase-1 draft

Status: draft. No code exists yet, so the exemption tables are empty by construction, not by
audit. Every `external_body`, `assume_specification`, and explicit `assume` added later must
be recorded here with rationale, owner, and review record, or CI fails the change.

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
  K4 linear matching. Proofs cover P1–P8 on the shipped code path under documented
  assumptions. No full-server verification is claimed.

## Proof exemptions (none yet — code does not exist)
| Location | Kind | Rationale | Owner | Review |
|---|---|---|---|---|
| — | — | — | — | — |

Rules: no undocumented `assume`/`external_body`/`assume_specification`; no silent additions;
each entry needs owner plus review record; CI detects unregistered exemptions and blocks.
The count below is a tripwire, not evidence: exemptions: 0, all recorded: yes (vacuous).

## Assumptions log
| Date | Assumption | Scope | Status |
|---|---|---|---|
| 2026-11-24 | Shell blocked; no build, test, or Verus run performed or claimed | whole route | open |
