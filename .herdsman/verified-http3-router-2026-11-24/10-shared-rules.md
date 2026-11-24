# Shared rules for every implementer (local branches only)

Repository worktree: `/home/takib/Documents/arafat-vai-office/worktrees/t-phase0` on
`local/t-phase0-spike`. Keep all Git operations local; never push, publish, fetch, or open a PR.
Stack: Rust workspace with a Verus-verified synchronous kernel crate, a thin TQUIC adapter
crate, and an HTTP/3 demo target. Read the repo layout plus `docs/VERIFIED_HTTP3_ROUTER_PRD.md`
(baseline) and `docs/verus-verified-router-plan.md` (roadmap) before coding.

## Must prove (quoted from 00-route.md)
P1 totality/panic-freedom; P2 executable refines `match_spec`; P3 no equal-priority ambiguity;
P4 canonical-path containment plus idempotence; P5 prefix confinement; P6 parameter soundness
with reconstruction; P7 ordered pseudo-header well-formedness; P8 explicit bounded work.
Each claim needs passing Verus evidence on the shipped code path, pinned toolchain,
documented assumptions, and independent spec sign-off.

## Setup
1. The Phase 0 branch and worktree already exist. Do not create another branch or worktree.
   Git metadata is read-only in the Codex sandbox; follow the Git metadata boundary below.
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

## Git metadata boundary
- Keep the normal workspace sandbox enabled. Do not change permissions, remount `.git`, or
  disable sandbox protections. Do not attempt `git add` or `git commit` from the agent pane.
- Leave implementation changes in the worktree. Report exact suggested atomic Conventional
  Commit groups. The orchestrator will request elevated permission for Git metadata writes; if
  Herdr cannot forward that approval, provide the user exact host-terminal commands.

## Checks
- Run one check at a time on the machine (build, test, Verus, lint, format), single-threaded
  where the tool allows, through `bash /home/takib/Documents/arafat-vai-office/worktrees/t-phase0/.herdsman/verified-http3-router-2026-11-24/run-check.sh <command>`.
- Never run two checks in parallel. If installation requires network or writes outside the
  worktree, request permission rather than changing the sandbox.
- A check that exits 0 without running anything is a false green: reports name what ran,
  counts, and the command's own exit code.

## Report
When done, write `/home/takib/Documents/arafat-vai-office/worktrees/t-phase0/.herdsman/verified-http3-router-2026-11-24/reports/t-phase0.md` with, in order: `STATUS: complete` or
`STATUS: blocked <reason>`; `needs:`; branch; worktree; base commit and changed files; exact
test and proof commands, pass counts and exit codes; suggested atomic commits; `decisions:`;
`handoff:`; `gaps:`.
Under 60 lines. Then reply with only that file path. After the report, make no more commits
until the next prompt. Never fabricate passing tests, proofs, benchmarks, or evidence.
