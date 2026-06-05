/**
 * Regression for issue ##2848 — "wheels-bot embeds a stale SHA in review
 * idempotency markers, causing review re-fires."
 *
 * Reviewer A/B comments carry an idempotency marker
 * (`<!-- wheels-bot:review-a:<pr>:<sha> -->` / `review-b`). The skill prompts
 * used to RE-DERIVE that <sha> at review time via `gh pr view --json
 * headRefOid`, which races with new pushes: between the workflow's checkout
 * and the model's `gh pr view` call a fresh push can move the PR head, so the
 * emitted marker SHA lagged the commit the review actually ran against. The
 * skip-check gate then failed to recognise an already-reviewed head and
 * Reviewer A re-fired on superseded commits while Reviewer B emitted
 * contradictory verdicts on different SHAs.
 *
 * Fix: capture the head SHA exactly once at the workflow level (it is already
 * what gets checked out) and thread it into the prompt as a command argument,
 * so the model emits the marker from the value it was handed instead of
 * re-deriving it. The model's Bash allowlist on these workflows is restricted
 * to `gh` + read-only `git` (no `echo` / `printenv`), so a step-level env var
 * would be unreadable by the model — the SHA must arrive in the prompt text,
 * the same channel the PR number already travels on.
 *
 *   - bot-review-a.yml : the `/review-pr` and `/respond-to-critique` commands
 *                        gain `${{ steps.pr.outputs.sha }}` (the SHA that the
 *                        Checkout step already pinned).
 *   - bot-review-b.yml : the checkout ref, the skip-check marker-pattern, and
 *                        the `/review-the-review` command all key off
 *                        `${{ github.event.review.commit_id }}` — the commit
 *                        Reviewer A's review (which B critiques) was attached
 *                        to — never the PR's drifting `pull_request.head.sha`.
 *   - review-pr.md / review-the-review.md / respond-to-critique.md : each
 *                        takes a `<head-sha>` argument and emits the marker
 *                        from it instead of from `gh pr view --json headRefOid`.
 *
 * This is a structural spec (no runtime): it reads the workflow YAML and the
 * prompt markdown and asserts the threading is wired. Modeled on
 * OnErrorFallbackGuardSpec.cfc and ConfigRoutesStaleDocUrlSpec.cfc.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("wheels-bot review marker SHA threading (issue ##2848)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");

			var reviewA = repoRoot & "/.github/workflows/bot-review-a.yml";
			var reviewB = repoRoot & "/.github/workflows/bot-review-b.yml";

			describe("bot-review-a.yml", () => {

				it("threads the checked-out SHA into the /review-pr command", () => {
					expect(fileExists(reviewA)).toBeTrue("Missing file: " & reviewA);
					var content = fileRead(reviewA);
					expect(
						reFindNoCase(
							"/review-pr\s+\$\{\{\s*steps\.pr\.outputs\.pr_num\s*\}\}\s+\$\{\{\s*steps\.pr\.outputs\.sha\s*\}\}",
							content
						) > 0
					).toBeTrue(
						"bot-review-a.yml must pass ${{ steps.pr.outputs.sha }} into the "
						& "/review-pr command so Reviewer A emits the marker from the "
						& "checked-out SHA, not a re-derived `gh pr view` head (issue ##2848)."
					);
				});

				it("threads the checked-out SHA into the /respond-to-critique command", () => {
					expect(fileExists(reviewA)).toBeTrue("Missing file: " & reviewA);
					var content = fileRead(reviewA);
					expect(
						reFindNoCase(
							"/respond-to-critique\s+\$\{\{\s*steps\.pr\.outputs\.pr_num\s*\}\}\s+\$\{\{\s*steps\.pr\.outputs\.sha\s*\}\}",
							content
						) > 0
					).toBeTrue(
						"bot-review-a.yml must pass ${{ steps.pr.outputs.sha }} into the "
						& "/respond-to-critique command — the response path shares the same "
						& "Run Reviewer A step and the same SHA race (issue ##2848)."
					);
				});

				it("never re-derives a SHA via `gh pr view --json headRefOid`", () => {
					expect(fileExists(reviewA)).toBeTrue("Missing file: " & reviewA);
					var content = fileRead(reviewA);
					// Response mode used to derive the SHA from `gh pr view --json
					// headRefOid` (the current head), which floats while Reviewer B
					// anchors its marker to github.event.review.commit_id — so once a
					// push lands mid-loop the two diverge and the response can't find
					// B's critique. The reviewed SHA must instead be read from the
					// triggering review-b comment. Asserting headRefOid is absent
					// keeps the floating derivation from creeping back (issue ##2848).
					expect(reFindNoCase("headRefOid", content) > 0).toBeFalse(
						"bot-review-a.yml must not derive a marker SHA from "
						& "`gh pr view --json headRefOid` — in response mode it floats to the "
						& "current head and diverges from Reviewer B's commit_id-anchored "
						& "marker once a push lands mid-loop. Extract the reviewed SHA from "
						& "the triggering review-b comment instead (issue ##2848)."
					);
				});

			});

			describe("bot-review-b.yml", () => {

				it("checks out github.event.review.commit_id, not the drifting head", () => {
					expect(fileExists(reviewB)).toBeTrue("Missing file: " & reviewB);
					var content = fileRead(reviewB);
					expect(
						reFindNoCase(
							"ref:\s*\$\{\{\s*github\.event\.review\.commit_id\s*\}\}",
							content
						) > 0
					).toBeTrue(
						"bot-review-b.yml must check out github.event.review.commit_id — "
						& "the commit Reviewer A's review (which B critiques) was attached "
						& "to — so B reviews exactly what A reviewed (issue ##2848)."
					);
				});

				it("keys the skip-check marker-pattern off commit_id", () => {
					expect(fileExists(reviewB)).toBeTrue("Missing file: " & reviewB);
					var content = fileRead(reviewB);
					expect(
						reFindNoCase(
							"marker-pattern:\s*'wheels-bot:review-b:\$\{\{\s*github\.event\.pull_request\.number\s*\}\}:\$\{\{\s*github\.event\.review\.commit_id\s*\}\}:'",
							content
						) > 0
					).toBeTrue(
						"bot-review-b.yml skip-check marker-pattern must key off "
						& "github.event.review.commit_id so the idempotency gate and the "
						& "emitted marker agree on the same SHA (issue ##2848)."
					);
				});

				it("never references the drifting pull_request.head.sha", () => {
					expect(fileExists(reviewB)).toBeTrue("Missing file: " & reviewB);
					var content = fileRead(reviewB);
					expect(
						reFindNoCase("github\.event\.pull_request\.head\.sha", content) > 0
					).toBeFalse(
						"bot-review-b.yml must not reference github.event.pull_request.head.sha — "
						& "both the checkout ref and the skip-check marker-pattern must key off "
						& "github.event.review.commit_id instead (issue ##2848)."
					);
				});

				it("threads commit_id into the /review-the-review command", () => {
					expect(fileExists(reviewB)).toBeTrue("Missing file: " & reviewB);
					var content = fileRead(reviewB);
					expect(
						reFindNoCase(
							"/review-the-review\s+\$\{\{\s*github\.event\.pull_request\.number\s*\}\}\s+\$\{\{\s*github\.event\.review\.id\s*\}\}\s+\$\{\{\s*github\.event\.review\.commit_id\s*\}\}",
							content
						) > 0
					).toBeTrue(
						"bot-review-b.yml must pass github.event.review.commit_id into the "
						& "/review-the-review command as the authoritative marker SHA (issue ##2848)."
					);
				});

			});

			describe("review prompts emit the marker from the passed SHA", () => {

				// Each prompt must stop re-deriving the marker SHA from
				// `gh pr view --json headRefOid` (which races with new pushes
				// mid-session) and instead use the <head-sha> the workflow now
				// passes as a command argument. Asserting headRefOid is gone is
				// the behavioral signal: a bare `<head-sha>` substring check
				// false-passes because review-pr.md already uses it in an
				// unrelated `git log origin/develop..<head-sha>` example.
				var prompts = [
					{path: repoRoot & "/.claude/commands/review-pr.md", name: "review-pr.md"},
					{path: repoRoot & "/.claude/commands/review-the-review.md", name: "review-the-review.md"},
					{path: repoRoot & "/.claude/commands/respond-to-critique.md", name: "respond-to-critique.md"}
				];

				for (var p in prompts) {
					// Capture the loop variable so the closure body binds the
					// current value, not the final iteration's value.
					(function(prompt) {
						it("no longer re-derives the SHA via `gh pr view --json headRefOid` in " & prompt.name, () => {
							expect(fileExists(prompt.path)).toBeTrue("Missing file: " & prompt.path);
							var content = fileRead(prompt.path);
							expect(reFindNoCase("headRefOid", content) > 0).toBeFalse(
								prompt.name & " must not derive the marker SHA from "
								& "`gh pr view --json headRefOid` — it races with new pushes "
								& "between checkout and review submission. Emit the marker from "
								& "the <head-sha> argument the workflow passes instead (issue ##2848)."
							);
						});
					})(p);
				}

			});

		});

	}

}
