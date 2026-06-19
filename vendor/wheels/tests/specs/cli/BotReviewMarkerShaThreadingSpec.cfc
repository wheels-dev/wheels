/**
 * Regression for issue ##2848 — "wheels-bot embeds a stale SHA in review
 * idempotency markers, causing review re-fires" — updated for the
 * single-reviewer consolidation (2026-06-11).
 *
 * Reviewer reviews carry an idempotency marker
 * (`<!-- wheels-bot:review-a:<pr>:<sha> -->` — the legacy `review-a` name is
 * retained for continuity). The skill prompt used to RE-DERIVE that <sha> at
 * review time via `gh pr view --json headRefOid`, which races with new
 * pushes: between the workflow's checkout and the model's `gh pr view` call a
 * fresh push can move the PR head, so the emitted marker SHA lagged the
 * commit the review actually ran against. The skip-check gate then failed to
 * recognise an already-reviewed head and the Reviewer re-fired on superseded
 * commits.
 *
 * Fix: capture the head SHA exactly once at the workflow level (it is already
 * what gets checked out) and thread it into the prompt as a command argument,
 * so the model emits the marker from the value it was handed instead of
 * re-deriving it. The model's Bash allowlist on these workflows is restricted
 * to `gh` + read-only `git` (no `echo` / `printenv`), so a step-level env var
 * would be unreadable by the model — the SHA must arrive in the prompt text,
 * the same channel the PR number already travels on.
 *
 * History: the original fix (##2848 / ##2865) covered bot-review-a.yml,
 * bot-review-b.yml, and the convergence-loop prompts. The Reviewer A /
 * Reviewer B critique loop was retired on 2026-06-11 (single-pass Reviewer);
 * the surviving surfaces this spec pins are:
 *
 *   - bot-review.yml      : threads `${{ steps.pr.outputs.sha }}` (the SHA
 *                           the Checkout step pinned) into `/review-pr`, and
 *                           never queries headRefOid.
 *   - bot-review-fork.yml : same threading for maintainer-labeled fork PRs,
 *                           plus the pull_request_target pwn-request
 *                           hardening from ##2871 (base-branch checkout only,
 *                           never the fork ref; persist-credentials off;
 *                           fork + `bot-review` label gating).
 *   - review-pr.md        : takes a `<head-sha>` argument and emits the
 *                           marker from it instead of from
 *                           `gh pr view --json headRefOid`.
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

			var review = repoRoot & "/.github/workflows/bot-review.yml";
			var reviewFork = repoRoot & "/.github/workflows/bot-review-fork.yml";
			var reviewPrompt = repoRoot & "/.claude/commands/review-pr.md";

			describe("bot-review.yml", () => {

				it("threads the checked-out SHA into the /review-pr command", () => {
					expect(fileExists(review)).toBeTrue("Missing file: " & review);
					var content = fileRead(review);
					expect(
						reFindNoCase(
							"/review-pr\s+\$\{\{\s*steps\.pr\.outputs\.pr_num\s*\}\}\s+\$\{\{\s*steps\.pr\.outputs\.sha\s*\}\}",
							content
						) > 0
					).toBeTrue(
						"bot-review.yml must pass ${{ steps.pr.outputs.sha }} into the "
						& "/review-pr command so the Reviewer emits the marker from the "
						& "checked-out SHA, not a re-derived `gh pr view` head (issue ##2848)."
					);
				});

				it("never re-derives a SHA via `gh pr view --json headRefOid`", () => {
					expect(fileExists(review)).toBeTrue("Missing file: " & review);
					var content = fileRead(review);
					// The SHA is captured exactly once from the pull_request event
					// payload at run start; querying the (drifting) current head via
					// `gh pr view` mid-run is the ##2848 race. Asserting headRefOid is
					// absent keeps the floating derivation from creeping back.
					expect(reFindNoCase("headRefOid", content) > 0).toBeFalse(
						"bot-review.yml must not derive a marker SHA from "
						& "`gh pr view --json headRefOid` — it floats to the current head "
						& "and diverges from the checked-out commit once a push lands "
						& "mid-run (issue ##2848)."
					);
				});

			});

			describe("bot-review-fork.yml (fork PR review via pull_request_target)", () => {

				it("checks out the BASE branch, never the fork ref (pwn-request hardening)", () => {
					expect(fileExists(reviewFork)).toBeTrue("Missing file: " & reviewFork);
					var content = fileRead(reviewFork);
					// pull_request_target runs in the base-repo context with secrets +
					// the write token. The working tree must stay on base so the local
					// wheels-bot-skip-check composite action is always trusted base code;
					// checking out the fork ref first is the classic pwn-request.
					expect(
						reFindNoCase(
							"ref:\s*\$\{\{\s*github\.event\.pull_request\.base\.ref\s*\}\}",
							content
						) > 0
					).toBeTrue(
						"bot-review-fork.yml must check out github.event.pull_request.base.ref "
						& "and never the fork head, so the local wheels-bot-skip-check composite "
						& "action always resolves to trusted base code (issue ##2871)."
					);
					expect(reFindNoCase("persist-credentials:\s*false", content) > 0).toBeTrue(
						"bot-review-fork.yml checkout must set persist-credentials: false under "
						& "pull_request_target (issue ##2871)."
					);
					// Negative side: the checkout `ref:` must never key off a
					// fork-controlled head ref. head.sha is referenced elsewhere (the
					// review marker, via env) — this guards only the checkout ref, the
					// value that lands in the working tree.
					expect(
						reFindNoCase(
							"ref:\s*\$\{\{\s*github\.event\.pull_request\.head\.",
							content
						) > 0
					).toBeFalse(
						"bot-review-fork.yml must NOT check out a fork head ref "
						& "(ref: ${{ github.event.pull_request.head.* }}) — that would put "
						& "fork-controlled code in the working tree, where the local "
						& "wheels-bot-skip-check composite action runs it (issue ##2871)."
					);
				});

				it("threads the validated head SHA into the /review-pr command (##2848)", () => {
					expect(fileExists(reviewFork)).toBeTrue("Missing file: " & reviewFork);
					var content = fileRead(reviewFork);
					expect(
						reFindNoCase(
							"/review-pr\s+\$\{\{\s*steps\.pr\.outputs\.pr_num\s*\}\}\s+\$\{\{\s*steps\.pr\.outputs\.sha\s*\}\}",
							content
						) > 0
					).toBeTrue(
						"bot-review-fork.yml must thread steps.pr.outputs.sha into /review-pr so "
						& "the fork review emits the marker from the checked-out SHA, matching the "
						& "internal Reviewer path (issue ##2848)."
					);
				});

				it("is gated on a fork PR carrying the maintainer-applied bot-review label", () => {
					expect(fileExists(reviewFork)).toBeTrue("Missing file: " & reviewFork);
					var content = fileRead(reviewFork);
					expect(
						reFindNoCase("github\.event\.pull_request\.head\.repo\.fork\s*==\s*true", content) > 0
					).toBeTrue(
						"bot-review-fork.yml must gate on head.repo.fork == true so it runs only "
						& "for fork PRs (internal PRs use bot-review.yml) (issue ##2871)."
					);
					expect(
						reFindNoCase("contains\(github\.event\.pull_request\.labels\.\*\.name,\s*'bot-review'\)", content) > 0
					).toBeTrue(
						"bot-review-fork.yml must require the maintainer-applied 'bot-review' "
						& "label — only write-access users can label, so a human vets the fork diff "
						& "before the bot runs (issue ##2871)."
					);
				});

			});

			describe("the review prompt emits the marker from the passed SHA", () => {

				// The prompt must not re-derive the marker SHA from
				// `gh pr view --json headRefOid` (which races with new pushes
				// mid-session) and instead use the <head-sha> the workflow
				// passes as a command argument. Asserting headRefOid is gone is
				// the behavioral signal: a bare `<head-sha>` substring check
				// false-passes because review-pr.md already uses it in an
				// unrelated `git log origin/develop..<head-sha>` example.
				it("no longer re-derives the SHA via `gh pr view --json headRefOid` in review-pr.md", () => {
					expect(fileExists(reviewPrompt)).toBeTrue("Missing file: " & reviewPrompt);
					var content = fileRead(reviewPrompt);
					expect(reFindNoCase("headRefOid", content) > 0).toBeFalse(
						"review-pr.md must not derive the marker SHA from "
						& "`gh pr view --json headRefOid` — it races with new pushes "
						& "between checkout and review submission. Emit the marker from "
						& "the <head-sha> argument the workflow passes instead (issue ##2848)."
					);
				});

			});

		});

	}

}
