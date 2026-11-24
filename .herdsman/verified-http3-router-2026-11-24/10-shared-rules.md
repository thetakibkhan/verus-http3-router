# Shared rules for every implementer (local branches only)

Repository: `/home/takib/Documents/arafat-vai-office/router`. No GitHub remote work in this route:
local branches only, never push, never publish, never open remote PRs without explicit permission.
Stack: Rust workspace with a Verus-verified synchronous kernel crate, a thin TQUIC adapter
crate, and an HTTP/3 demo target. Read the repo layout plus `docs/VERIFIED_HTTP3_ROUTER_PRD.md`
(baseline) and `docs/verus-verified-router-plan.md` (roadmap) before coding.

## Must prove (quoted from 00-route.md)
P1 totality/panic-freedom; P2 executable refines `match_spec`; P3 no equal-priority ambiguity;
P4 canonical-path containment plus idempotence; P5 prefix confinement; P6 parameter soundness
with reconstruction; P7 ordered pseudo-header well-formedness; P8 explicit bounded work.
Each claim needs passing Verus evidence on the shipped code path, pinned toolchain,
documented assumptions, and independent spec sign-off.

## Setup (deferred until shell works; shell is currently blocked)
1. Branch from the repo HEAD: `local/<task>` (e.g. `local/t-k2-canon`). One worktree per task
   under `<repo-parent>/worktrees/<task>` once the sandbox is fixed. Until then, do not start.
2. Toolchain pins (Rust, Verus revision, Z3, TQUIC, lockfile) are set in Phase 0 and recorded
   in the README; every later task builds on those pins and never upgrades silently.
3. No test database is expected by the PRD; if a task needs a local service, it uses a
   throwaway instance and tears it down. Never touch another task's files or state.

## Code standard
- Follow the PRD exactly; do not add unrequested features or a verified Trie unless US-048
  is approved on benchmark evidence.
- Keep the verified kernel synchronous and separate from async networking. Verus code uses
  index loops, no `async`, no trait objects for handlers; the kernel returns a route ID or a
  typed rejection, never a boxed handler.
- Preserve the small, lossless TQUIC adapter: order, duplicates, and header bytes unchanged,
  no second URL decoding pass, no handler selection inside the adapter.
- Small focused functions, early returns, meaningful names. Tests first for every behaviour
  change: a failing test, then the code. Keep kernel, proofs, tests, benches, and docs in sync.
- Formal claims need real passing Verus proofs. Never use undocumented `assume`,
  `external_body`, or `assume_specification`. Every trusted item goes in `TCB.md` with
  rationale, owner, and review record.
- Conventional commits (`feat:`, `fix:`, `test:`, `docs:`, `chore:`), one logical change per
  commit, clean history traceable to PRD story IDs. Review `git status` plus the staged diff
  before every commit. Never commit secrets, keys, credentials, or local env files.

## Checks
- Run one check at a time on the machine (build, test, Verus, lint, format), single-threaded
  where the tool allows. Shell is blocked, so no checks run yet; every report records them
  under `gaps:` as not run until the sandbox is fixed.
- A check that exits 0 without running anything is a false green: reports name what ran,
  counts, and the command's own exit code.

## Report
When done, write `<route>/reports/<task>.md` with, in order: `STATUS: complete` or
`STATUS: blocked <reason>`; `needs:` (decisions for orchestrator or user, or `none`);
branch; worktree; local head commit; exact test and proof commands with pass counts;
`decisions:`; `handoff:` (changes another task's files need, never edits there); `gaps:`.
Under 60 lines. Then reply with only that file path. After the report, make no more commits
until the next prompt. Never fabricate passing tests, proofs, benchmarks, or evidence.
