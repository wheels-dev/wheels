# Issue #1942: LuCLI: tracking issue for Phases 2-4

## Verdict
DEFER (tracking-issue hygiene only; no code change)

This is an umbrella/tracking issue — nothing to "fix" in code. Recommended treatment: **update the checklist to reflect merged work, narrow scope to the three still-open children, and either retitle or close-after-children**. Do NOT close yet because #1944, #1945, #1946 remain open and the tracker is still useful for GA readiness visibility.

## Summary
Umbrella issue tracking LuCLI Phases 2-4 (remaining generators, package-manager swap, 3.1 release readiness). Most child issues are done; a stale checklist makes status opaque ahead of 4.0 GA.

## Root cause
Not a bug. The issue body shows 9 unchecked child items, but `gh issue list` confirms 6 are already closed:

- CLOSED: #1943 (new-app scaffold), #1947 (module distribution), #1948 (docs), #1949 (E2E testing), #1950 (console REPL)
- OPEN:   #1944 (stretch generators), #1945 (Homebrew formula), #1946 (Chocolatey package)

Evidence:
- `cli/lucli/Module.cfc` + `cli/lucli/services/` exist and are wired (confirmed via Memory note `project_wheels_cli_lucli.md`: "Phase 1 done, Phase 2 validated (2667 tests pass), Phase 3 distribution shipped").
- Memory note `project_lucli_phase1.md`: "All LuCLI PRs merged. Profiles, placeholder, registry all landed."
- Memory note `project_lucli_1_0_cfcamp.md`: LuCLI 1.0.0 + Lucee-org repo move is the gating signal for updating Homebrew/Chocolatey formulas — which is exactly #1945/#1946.
- Also note: CLAUDE.md treats `wheels mcp wheels` as the canonical surface already, implying Phase 4 MCP wiring is effectively shipped.

## Files to change
Only GitHub metadata (via `gh` CLI) — no repo files.

- Issue #1942 body: re-render checklist with `[x]` for closed children, add brief "status as of 4.0 GA prep" note, optionally retitle to `LuCLI: remaining work for 4.0 GA (Phase 3 package managers + stretch generators)`.
- (Optional) labels: add `tracking` label if one exists; remove `phase:4-lucli-dx` only if redundant (leave it — still accurate).

No code, docs, tests, or config changes.

## Implementation steps
1. Re-verify child state (single source of truth = `gh`):
   ```
   gh issue list --repo wheels-dev/wheels --state all \
     --search "1943 1944 1945 1946 1947 1948 1949 1950 in:number" \
     --json number,title,state,closedAt
   ```
2. Edit the issue body with `gh issue edit 1942 --repo wheels-dev/wheels --body-file -` using an updated checklist:
   - Phase 2 — Remaining: `[x] #1943`, `[ ] #1944`
   - Phase 3 — Package Manager Swap: `[ ] #1945`, `[ ] #1946`, `[x] #1947`
   - Phase 4 — Ship Wheels 3.1: `[x] #1948`, `[x] #1949`, `[x] #1950`
3. Prepend a dated status block: "Updated YYYY-MM-DD: Phase 2 service layer + Phase 4 closed; 3 items remain — #1944 (stretch generators), #1945/#1946 (formula updates, blocked on LuCLI 1.0.0 release + Lucee-org repo move per Memory note `project_lucli_1_0_cfcamp.md`)."
4. Explicitly note the #1945/#1946 blocker in the issue so readers don't re-investigate: "Blocked: waiting on LuCLI 1.0.0 tag and repo move to Lucee org before bumping formulas."
5. Decide fate at 4.0 GA cut:
   - If #1944 defers past 4.0 → split it out of this umbrella and close #1942 as "superseded by per-phase trackers".
   - Otherwise close #1942 automatically when the last open child closes (add `closes #1942` to the final PR).
6. Do not touch `cli/lucli/PLAN.md` — the issue already references it as the source plan; content is historical.

## Testing
None — metadata-only change. Verification is visual:
- `gh issue view 1942 --repo wheels-dev/wheels` shows updated checkboxes and status note.
- Cross-check each `[x]` against `gh issue view <n> --json state`.
- No `wheels test run` / `bash tools/test-local.sh` needed.

## Risk & dependencies
- **Related:** #1943 (closed), #1944, #1945, #1946, #1947 (closed), #1948-1950 (closed). Upstream: LuCLI 1.0.0 release at `~/GitHub/bpamiri/LuCLI` and move to Lucee org (`project_lucli_1_0_cfcamp.md`).
- **Backwards compat:** N/A — no code.
- **Cross-engine:** N/A.
- **Migration / DB / config:** N/A.
- **Risk:** Near zero. Only risk is mis-checking a box; mitigated by step 1 re-verification.
- **Commit conventions:** N/A (no commit). If any follow-up doc edit is made, scope would be `docs` per CLAUDE.md (note: `cli` is also valid; prefer `docs` for plan-file tweaks).

## Effort estimate
S (<2h) — ~15 min of `gh` edits + decision on whether to split #1944 out.
