# Route: verified-http3-router — 2026-11-24

## Decisions
- Source of truth: PRD `docs/VERIFIED_HTTP3_ROUTER_PRD.md` is the requirements baseline; boss plan `docs/verus-verified-router-plan.md` is the architecture and verification roadmap.
- Boss draft was found at `docs/verus-verified-router-plan.md` (earlier search showed only the PRD; file confirmed readable this turn).
- Team: Phase-0 implementer Codex GPT-6.2-Sol at medium effort; independent reviewer Claude Code Opus at high effort. Muse is unavailable in this environment. The user approved this dispatch on 2026-11-24.
- Runner/shape: Herdr panes, isolated local branches and one worktree per task. Phase 0 only is dispatched. Never push, publish, or create remote PRs.
- Git baseline: `main` and `local/t-phase0-spike` began at `75ad11fc89da36626612791e7f70142873d3bcb3`. The primary checkout is on `main`; the task worktree is `/home/takib/Documents/arafat-vai-office/worktrees/t-phase0`.
- Env policy: shell and Cargo are available. Verus and Z3 are absent at launch, which Phase 0 must provision and pin. No build, test, proof, or HTTP/3 demo is claimed before the implementer reports evidence.
- Git policy: small atomic Conventional Commits per logically complete change; review status and staged diff before each commit; no remote operations.

## Must prove (PRD P1–P8, shipped kernel)
- P1 totality/panic-freedom; P2 executable refines `match_spec`; P3 no equal-priority ambiguity; P4 canonical-path containment plus idempotence; P5 prefix confinement; P6 parameter soundness with reconstruction; P7 ordered pseudo-header well-formedness; P8 explicit bounded work. Each claim needs passing Verus evidence on the shipped code path, pinned toolchain, documented assumptions, and independent spec sign-off.

## PRD vs boss plan (no silent inventions)
| Area | PRD (baseline) | Boss plan (roadmap) | Standing |
|---|---|---|---|
| Scope | Path-only, no vhost selection (Q2) | Asks vhost question | PRD answers: validate authority, no selection |
| Syntax | Literals, `:param`, terminal catch-all only | Asks syntax question | PRD answers: no regex/optional/middle wildcards |
| Matching | Case-sensitive, strict trailing slash | Asks case/slash question | PRD answers: strict distinction |
| Table | Immutable at startup, no hot reload | Asks static vs reload | PRD answers: rebuild plus restart |
| Proofs | P1–P8 mandatory on shipped path | P1–P8 spec-first sketch | Aligned; PRD narrows P1 to represented inputs plus assumptions |
| P7 basis | RFC 9114/9110 aligned, TQUIC scope | RFC rules from memory, check 4.3.1 | Phase-1 must verify RFC text; do not trust memory |
| Perf | p99 budget agreed after baseline | Budget plus optional Trie | No numeric budget is approved; do not invent one |
| Evidence | 24h zero-mismatch fuzz, mutation, interop | Differential, fuzz, mutation | PRD gate is stricter; PRD wins |

## Deferred (PRD Section 5, needs spec sign-off)
1. Literal `%` and residual-escape handling after one decode.
2. Doubled separators, root-escaping `..`, encoded backslashes, query strings, dot segments with trailing `/`.
3. Route-ID type/range, duplicate-ID policy, priority range and ties across method/HEAD fallback.
4. OPTIONS precedence, allowed-method ordering, unknown-path OPTIONS outcome.
5. Authority/Host compatibility scope and CONNECT recognition vs rejection.
6. Numeric safe defaults and maximum configured limits.
7. Benchmarked p99 overhead budget after baseline results.

## Task table (epic -> branch -> contract -> phase)
| Task | Branch | Worktree | Agent | Pane | Contract | Phase | PRD stories |
|---|---|---|---|---|---|---|---|
| t-phase0 | local/t-phase0-spike | `/home/takib/Documents/arafat-vai-office/worktrees/t-phase0` | im-t-phase0 | w2:p2 | 11-task-t-phase0.md | 0 | E01 US-001..005 |
| t-spec | local/t-spec-phase1 | pending | pending | pending | 12-task-t-spec.md | 1 | E02 US-006..010 |
| t-k2 | local/t-k2-canon | pending | pending | pending | 13-task-t-k2.md | 2 | E03 US-011..015 plus E08 |
| t-k3k4 | local/t-k3k4-table-match | pending | pending | pending | 14-task-t-k3k4.md | 3 | E04 US-016..021, E05 US-022..027, plus E08 |
| t-k1 | local/t-k1-headers | pending | pending | pending | 15-task-t-k1.md | 4 | E06 US-028..033 |
| t-integrate | local/t-integrate-demo | pending | pending | pending | 16-task-t-integrate.md | 5 | E07 US-034..039, E08 US-040..044, E09 US-045..047, E10 |
| t-trie-opt | local/t-trie-conditional | pending | pending | pending | 17-task-t-trie-opt.md | 6 | E09 US-048 conditional only, not authorised |

## Checklist
- [x] Read PRD plus boss plan; recorded baseline vs roadmap -- `docs/VERIFIED_HTTP3_ROUTER_PRD.md`, `docs/verus-verified-router-plan.md`
- [x] Shared rules, task contracts 11-17, reviewer brief and wrapper are present -- `.herdsman/verified-http3-router-2026-11-24/`
- [x] Shell access verified; Herdr socket works with elevated permission; Git metadata writes need elevation -- `herdsman doctor`, `herdr agent list`
- [ ] Review `git status` and staged diff before every commit
- [x] Load limits set; wrapper passed a Cargo version check normally and with `HERDSMAN_PROBES=off` -- both exited 0; the latter reported lock-only mode
- [x] Create `local/t-phase0-spike` worktree -- `/home/takib/Documents/arafat-vai-office/worktrees/t-phase0`, clean at `75ad11f`
- [ ] Start Phase-0 implementer after route check passes; execute phases 0-5
- [ ] Independent spec sign-off before any P1–P8 implementation claim (E02 gate)
- [ ] Trie only if p99 budget justifies plus explicit approval; reviewer pass per milestone; no story Done without acceptance evidence

## Run state
- 2026-11-24: initial planning artifacts and PRD documents are present in the initial commit.
  No builds, tests, proofs, demos, or benchmarks are claimed.
- 2026-11-24: earlier file-tools-only setup added the Phase-1 spec stub and root `TCB.md`.
  Those documents remain proposals with all proof evidence pending. The initial commit contains
  the planning artifacts. Current launch state is recorded by later `herdsman route log` entries.
- 17:02 Phase 0 worktree and Herdr pane created; wrapper checks passed; launch checklist passed.
- 17:04 Started Phase 0 implementer im-t-phase0 in pane w2:p2; Codex is working in the isolated branch worktree.
- 17:07 Waiter smoke check returned TICK after 60 seconds; agent status is working and route health is clean.
- 2026-11-24: user steered the Phase-0 implementer to CommandCode DeepSeek V4.1 Flash. It reran
  the pinned offline build/test, the real valid/invalid Verus checks, the proof CI script, the
  HTTP/3 demo, and the static checks documented in `reports/t-phase0.md` and the audit logs.
- 2026-11-24: `claude-ds` was unavailable; the user authorized CommandCode plus Codex fallback.
- 2026-11-24: independent GPT-6 Luna High Codex review found no P0/P1 code defects but returned
  VERDICT FIX because hosted CI publication and an independent clean-machine/container replay
  remain open. P1–P8 remain unclaimed.
- 2026-11-24: clean Ubuntu 24.04 container replay passed on `e757847dfced9dab426e13f39d25d2a766033b16` (image digest `sha256:562111b88caa79c71391c0c4d3c2114a7d5c35915c20561fd893cb1e07929e6b`, snapshot `d7f01b9cf7e06b71a048e1c0bf19f8559247813bc74335cc0333dc9fc5e91b7e`; build/test/Verus+/−/proof-CI/HTTP3/fmt pass; log `clean-container-e757847.log`). Hosted CI/artifact publication is the only open Phase 0 acceptance blocker; P1–P8 remain unclaimed.
- 2026-11-24: provenance correction: reran the clean-container replay from a `git -c tar.umask=0022 archive` extraction of `e757847dfced9dab426e13f39d25d2a766033b16`; canonical sanitized-tree manifest `87721388b91464a82b4ef117ddf9a84935c09c18098d1d2498631015e2ebba70` is byte-identical to `git cat-file` blobs and tree modes; the container had no `.git` and used the manifest label; build/test/Verus+/−/proof-CI/HTTP3/fmt pass; evidence `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/clean-container-e757847-provenance.log` + `.herdsman/verified-http3-router-2026-11-24/reports/t-phase0-logs/clean-container-e757847.manifest.txt`. Hosted CI/artifact publication remains the only open Phase 0 acceptance blocker; P1–P8 remain unclaimed.
