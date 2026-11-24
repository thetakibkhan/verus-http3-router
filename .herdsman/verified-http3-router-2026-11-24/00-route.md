# Route: verified-http3-router — 2026-11-24

## Decisions
- Source of truth: PRD `docs/VERIFIED_HTTP3_ROUTER_PRD.md` is the requirements baseline; boss plan `docs/verus-verified-router-plan.md` is the architecture and verification roadmap.
- Boss draft was found at `docs/verus-verified-router-plan.md` (earlier search showed only the PRD; file confirmed readable this turn).
- Team: orchestrator Muse Spark 1.3; implementer claude-ds (DeepSeek V4.1 Flash); reviewer Muse Spark 1.3 (independent).
- Runner/shape: isolated local branches only. Never push, publish, or create remote PRs without explicit permission.
- Env policy: shell execution is blocked (bubblewrap loopback failure). No implementation, build, test, or Verus run is claimed. Resolve the sandbox blocker before Phase-0 execution. No commits made this turn.
- Git policy: small atomic commits per logically complete change, conventional messages, separate unrelated changes, review `git status` plus staged diff before every commit, clean history traceable to PRD stories. Commits are deferred until shell works.

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
| Task | Branch | Contract | Phase | PRD stories |
|---|---|---|---|---|
| t-phase0 | local/t-phase0-spike | 11-task-t-phase0.md | 0 | E01 US-001..005 |
| t-spec | local/t-spec-phase1 | 12-task-t-spec.md | 1 | E02 US-006..010 |
| t-k2 | local/t-k2-canon | 13-task-t-k2.md | 2 | E03 US-011..015 plus E08 |
| t-k3k4 | local/t-k3k4-table-match | 14-task-t-k3k4.md | 3 | E04 US-016..021, E05 US-022..027, plus E08 |
| t-k1 | local/t-k1-headers | 15-task-t-k1.md | 4 | E06 US-028..033 |
| t-integrate | local/t-integrate-demo | 16-task-t-integrate.md | 5 | E07 US-034..039, E08 US-040..044, E09 US-045..047, E10 |
| t-trie-opt | local/t-trie-conditional | 17-task-t-trie-opt.md | 6 | E09 US-048 conditional only, not authorised |

## Checklist
- [x] Read PRD plus boss plan; recorded baseline vs roadmap
- [x] Shared rules, phase task contracts 11-17, reviewer brief, run-check.sh written (plan-only, untested)
- [ ] Shell sandbox blocker STILL PENDING (bubblewrap loopback fails; shell, git, builds, Verus all unrunnable)
- [ ] After shell works: `git status` plus staged-diff review, `chmod +x run-check.sh`, set load limits, test wrapper, commit plan-only files
- [ ] Then create `local/t-phase0-spike` and start Phase-0 execution in phase order 0-5
- [ ] Independent spec sign-off before any P1–P8 implementation claim (E02 gate)
- [ ] Trie only if p99 budget justifies plus explicit approval; reviewer pass per milestone; no story Done without acceptance evidence

## Run state
- 2026-11-24: plan-only route setup complete. Shell blocked, so Phase-0 execution is
  deferred: no branches created, no commits made, no pushes, no builds, tests, proofs, or
  benchmarks run or claimed. Uncommitted plan-only files: `.gitignore`, route folder
  (00-route.md, 10-shared-rules.md, 11-17 task contracts, 20-reviewer.md, run-check.sh).
  Next: fix sandbox, then `git status`, wrapper test, commit, Phase 0.
- 2026-11-24: file-tools-only advance, shell still blocked (no shell retry loop). Added
  `docs/formal-specification.md` Phase-1 stub (proposed grammar, decision types, reference
  sketches, P1–P8 matrix with all evidence PENDING, proposed adversarial outcomes, empty
  sign-off) and root `TCB.md` skeleton (0 exemptions, assumption logged). Nothing approved,
  nothing proved, nothing run. Shell-dependent work still gated: `git status`/diff review,
  branch creation, `chmod +x` plus load-limit setup plus two-pass `run-check.sh` test,
  commits, builds, tests, Verus runs, TQUIC demo.
