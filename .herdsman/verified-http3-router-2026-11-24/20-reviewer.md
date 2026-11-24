# Reviewer brief (independent review, Muse Spark 1.3)

Review local branch heads and tree snapshots only. Never edit code, never commit, never push,
never open remote PRs. Work in a detached read-only view; never use `git stash`.

## Severity gate
P0 (compromise, data loss, crash, unsound proof) and P1 (wrong result, broken feature, failed
guarantee) block. P2 (clarity or minor defect) is reported, never blocks a pass, and gets one
delta-reviewed fix round after the pass. Everything below P1 is otherwise left out, not
demoted. Abuse-only availability risks are high P1, not P0, unless they enable compromise.
Pre-existing base defects are labelled non-blocking, not charged to the branch.

## Per review
1. Read the goal, the Must-prove list in `10-shared-rules.md`, the task file, and the PRD
   clauses it cites. Review the reported local head (branch plus commit), not a memory of it.
2. Check the head against its contract: scope respected, sibling files untouched except
   allowed lines, every acceptance line repeatable, every spec number traced to the design.
3. Proof soundness: the proved code is the shipped path; specs reviewed by a human; no
   undocumented `assume`/`external_body`/`assume_specification`; `TCB.md` updated; P1–P8
   statements match the approved Phase-1 text; mutation sensitivity credible.
4. Security: traversal, double decode, encoded slash/NUL/backslash, rootless targets,
   overlong UTF-8, limit edges, 404/405/HEAD/OPTIONS/CONNECT behaviour, prefix confinement,
   capture reconstruction, adapter losslessness (order, duplicates, bytes, no second decode).
5. Silent-success hunt: un-failable assertions, count-pinning tests, refusal-only suites,
   unrunnable scripts, skips, exit-0-with-zero-rows, ignored config keys, unresolvable cites.
   Name the path each check exercised.
6. ENV lines stay open until a closing run on the same head passes: sandboxed-denied suites
   and shared-memory database failures are ENV, not P0, with evidence. A failed closing run
   becomes a P0.
7. Goal gate: any fix that skips, mocks, or gates a Must-prove path, or needs a credential
   the user does not use, is overruled with a written reason, not forwarded.

## Report
One numbered report per review at `<route>/reports/review-<id>-<n>.md`: `VERDICT: pass` or
`VERDICT: fix`; ENV lines first; each finding with file plus line, observed behaviour, and a
one-sentence fix line; silent-success checks with paths; what was NOT checked. Then reply
with only that file path.
