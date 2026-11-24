# Task t-trie-opt: optional verified Trie (E09 US-048, conditional)

Branch `local/t-trie-conditional` from the accepted integrator HEAD. Worktree
`<repo-parent>/worktrees/t-trie`. Report file `<route>/reports/t-trie.md`.

Due: set at launch from `date`. This task starts only with explicit user approval after the
p99 gate result exists. It is currently NOT authorised to start.

Must prove subset: P2 refinement (`trie_match` equals `match_spec`/flat-table semantics) plus
applicable P1/P3/P5/P6/P8 for the new path. Same bar as the linear matcher, no shortcuts.

## Problem (conditional)
If the linear matcher misses the agreed p99 budget, routing needs a faster structure without
changing meaning.

## Scope
1. US-048 AC1: if the linear matcher meets the agreed budget, no Trie ships; the decision
   and its rationale are documented and this task closes without code.
2. US-048 AC2: if approved, trie matching proved equivalent to the same `match_spec` and
   flat-table semantics that Stage A uses.
3. US-048 AC3: the approved Trie passes the same functional, security, and regression suites
   and shows a measured benefit on the agreed workloads.

## Out of scope
Everything unless the gate fails and the user approves. Never a speculative optimisation.

## Overlap
Touches matcher internals owned by t-k3k4; works on the combined HEAD, never on the old
branch.

## Acceptance
- Either documented no-Trie decision, or a proved Trie with identical guarantees, green
  suites, and measured gain. No silent performance exception.
