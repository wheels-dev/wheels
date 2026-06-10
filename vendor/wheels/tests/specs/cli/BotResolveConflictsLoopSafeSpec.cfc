component extends="wheels.WheelsTest" {

	// Regression for issue ##2849 (a follow-up to ##2847).
	//
	// The "Verify resolution, push, or escalate (loop-safe)" step in
	// .github/workflows/bot-resolve-conflicts.yml runs under `set -euo pipefail`.
	// It finishes a resolved-but-uncommitted merge with `git commit --no-edit`,
	// then — if no new commit landed — escalates by applying the
	// `conflict:needs-human` label and posting a comment carrying the
	// `wheels-bot:conflict-attempted` marker. The freshen sweep's skip-check
	// keys off that marker, so the marker is what stops the resolver from being
	// re-dispatched on every cycle.
	//
	// The bug: a *bare* `git commit --no-edit` is fatal under `set -e`. If the
	// commit itself exits non-zero (e.g. a pre-commit hook rejects it), the step
	// aborts at that line, BEFORE the escalation block runs. No marker is posted,
	// the PR stays DIRTY, and the freshen sweep re-dispatches this resolver every
	// cycle (runaway loop). The author's original comment anticipated the
	// "merge aborted -> no new commit" path (which correctly falls through to
	// escalation) but not the "the commit command itself failed" path.
	//
	// The fix arms an exit-time trap that posts the marker on ANY non-zero exit
	// of the step (a hook-rejected commit, a failed push, or any command added
	// later) — satisfying the acceptance criterion that "any failure on the
	// resolve path leaves a conflict-attempted marker". This spec pins that
	// invariant with a static check of the workflow, since the step's behaviour
	// (gh / git side effects against a real checkout) cannot be exercised in a
	// unit test.

	function run() {

		describe("bot-resolve-conflicts.yml loop-safe escalation (issue ##2849)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var workflow = repoRoot & "/.github/workflows/bot-resolve-conflicts.yml";

			// Scope assertions to the finalize step (the last step in the file)
			// so we test the loop-safe escalation path specifically, not the
			// separate code-conflict escalation step that shares the same marker.
			var stepAnchor = "Verify resolution, push, or escalate (loop-safe)";

			it("protects the merge commit so a failed commit cannot bypass escalation", () => {
				expect(fileExists(workflow)).toBeTrue("Missing file: " & workflow);
				var src = fileRead(workflow);

				var anchorPos = find(stepAnchor, src);
				expect(anchorPos > 0).toBeTrue("Could not find the '" & stepAnchor & "' step in " & workflow);
				var block = mid(src, anchorPos, len(src) - anchorPos + 1);

				// The step should still finish a resolved merge with a commit.
				var commitPos = reFindNoCase("git[[:space:]]+commit[[:space:]]+--no-edit", block);
				expect(commitPos > 0).toBeTrue(
					"The finalize step should still finish a resolved-but-uncommitted merge with "
					& "`git commit --no-edit`. See issue ##2849."
				);

				// Protection takes one of the two shapes blessed by the acceptance
				// criteria: an exit-time trap armed BEFORE the commit, or the commit
				// itself guarded so its failure falls through to escalation.
				var trapPos = reFindNoCase("trap[[:space:]]+[^\n]*EXIT", block);
				var trapArmedBeforeCommit = trapPos > 0 && trapPos < commitPos;
				var commitIsGuarded =
					   reFindNoCase("if[[:space:]]+![^\n]*git[[:space:]]+commit[[:space:]]+--no-edit", block) > 0
					|| reFindNoCase("git[[:space:]]+commit[[:space:]]+--no-edit[^\n]*\|\|", block) > 0;

				expect(trapArmedBeforeCommit || commitIsGuarded).toBeTrue(
					"issue ##2849: under `set -euo pipefail` a bare `git commit --no-edit` that exits "
					& "non-zero (e.g. a pre-commit hook rejects it) aborts the step BEFORE the "
					& "escalation block runs, so no `conflict-attempted` marker is posted and the "
					& "freshen sweep re-dispatches the resolver forever. The finalize step MUST "
					& "either arm an exit-time trap before the commit (`trap ... EXIT`) or guard the "
					& "commit itself (`if ! git commit ...` / `git commit ... ||`) so the failure "
					& "falls through to the escalation path."
				);
			});

			it("always posts the conflict-attempted marker and needs-human label on the escalation path", () => {
				var src = fileRead(workflow);

				var anchorPos = find(stepAnchor, src);
				expect(anchorPos > 0).toBeTrue("Could not find the '" & stepAnchor & "' step in " & workflow);
				var block = mid(src, anchorPos, len(src) - anchorPos + 1);

				expect(reFindNoCase("wheels-bot:conflict-attempted:", block) > 0).toBeTrue(
					"The finalize step must post the `wheels-bot:conflict-attempted` marker when "
					& "resolution does not complete — the freshen skip-check keys off it to stop "
					& "re-dispatching the resolver. See issue ##2849."
				);
				expect(reFindNoCase("conflict:needs-human", block) > 0).toBeTrue(
					"The finalize step must apply the `conflict:needs-human` label on escalation. "
					& "See issue ##2849."
				);
				expect(reFindNoCase("gh[[:space:]]+pr[[:space:]]+comment", block) > 0).toBeTrue(
					"The finalize step must publish the marker via `gh pr comment`. See issue ##2849."
				);
			});

		});

	}

}
