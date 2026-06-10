/**
 * Regression for the convergence/deadlock loop — follow-up to issue ##2848
 * and PR ##2865.
 *
 * ##2865 fixed stale-SHA idempotency markers for Reviewer A (`review-pr.md` /
 * `respond-to-critique.md`) and Reviewer B (`review-the-review.md`) by
 * capturing the head SHA exactly once at the workflow level and threading it
 * into the prompt as an explicit `<head-sha>` argument, instead of letting the
 * model re-derive it mid-session via `gh pr view --json headRefOid` (which
 * races with pushes landing between checkout and review submission, so the
 * emitted marker SHA lagged the commit the run actually executed against).
 *
 * The SAME bug class lived in the two convergence-loop commands, which were
 * out of scope for ##2865 because they fire on a different trigger path (the
 * convergence/deadlock loop, not the pull_request / review-submitted paths):
 *
 *   - bot-address-review.yml / address-review.md : the implementer that
 *     applies the A/B consensus and pushes to the PR branch. The prompt
 *     re-derived the marker SHA via `gh pr view --json ...headRefOid` and
 *     emitted `wheels-bot:address-review:<pr>:<sha>:` markers from it.
 *   - bot-advisor.yml / advise-on-deadlock.md : the deadlock tie-breaker. The
 *     prompt re-derived via `gh pr view --json comments,headRefOid` and emitted
 *     `wheels-bot:advisor:<pr>:<sha>` + `converged-*` markers from it.
 *
 * Fix (mirrors ##2865): capture the head SHA once at the workflow level and
 * thread it into the prompt as a `<head-sha>` argument.
 *   - bot-advisor.yml already resolves the SHA in a step
 *     (`steps.pr.outputs.sha`); it now passes that into `/advise-on-deadlock`.
 *   - bot-address-review.yml gains an equivalent resolve step that captures
 *     `headRefOid` and passes `steps.pr.outputs.sha` into `/address-review`.
 *     Its checkout stays branch-name-keyed (the implementer commits and pushes
 *     back; a detached-HEAD SHA checkout would break the push), so the
 *     resolved SHA is the marker's `<sha-before>` — the head at run start.
 *   - address-review.md / advise-on-deadlock.md each take `<head-sha>` and emit
 *     their markers from it instead of from `gh pr view --json headRefOid`.
 *
 * The model's Bash allowlist on these workflows is gh + read-only git (no
 * echo/printenv), so a step-level env var would be unreadable — the SHA must
 * travel in the prompt text, the same channel the PR number already uses. The
 * prohibition in the prompts is narrowly scoped to "don't re-derive the SHA":
 * `gh pr view` stays the normal way to read comments / reviews / diff,
 * otherwise the model floods permission denials and posts nothing (see the
 * PR ##2865 history with Reviewer A).
 *
 * Note the asymmetry: resolving `headRefOid` once at the WORKFLOW level is the
 * fix, so it must be PRESENT in the workflow YAML; re-deriving it in the PROMPT
 * is the bug, so it must be ABSENT from the prompt markdown.
 *
 * This is a structural spec (no runtime): it reads the workflow YAML and the
 * prompt markdown and asserts the threading is wired. Modeled on
 * BotReviewMarkerShaThreadingSpec.cfc.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("wheels-bot convergence-loop marker SHA threading (##2848 / ##2865 follow-up)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");

			var advisor = repoRoot & "/.github/workflows/bot-advisor.yml";
			var addressReview = repoRoot & "/.github/workflows/bot-address-review.yml";

			describe("bot-advisor.yml", () => {

				it("threads the resolved head SHA into the /advise-on-deadlock command", () => {
					expect(fileExists(advisor)).toBeTrue("Missing file: " & advisor);
					var content = fileRead(advisor);
					expect(
						reFindNoCase(
							"/advise-on-deadlock\s+\$\{\{\s*env\.PR_NUMBER\s*\}\}\s+\$\{\{\s*steps\.pr\.outputs\.sha\s*\}\}",
							content
						) > 0
					).toBeTrue(
						"bot-advisor.yml must pass ${{ steps.pr.outputs.sha }} into the "
						& "/advise-on-deadlock command so the advisor emits its advisor + "
						& "convergence markers from the SHA the workflow already resolved and "
						& "checked out, not a re-derived `gh pr view` head (issue ##2848 / PR ##2865)."
					);
				});

			});

			describe("bot-address-review.yml", () => {

				it("resolves the head SHA once at the workflow level", () => {
					expect(fileExists(addressReview)).toBeTrue("Missing file: " & addressReview);
					var content = fileRead(addressReview);
					// Mirrors bot-advisor.yml: the SHA is resolved once in a step
					// (via `gh pr view --json ...headRefOid`) so a stable value can be
					// threaded into the prompt. Without this the threaded
					// `steps.pr.outputs.sha` would expand to empty (issue ##2848).
					expect(reFindNoCase("headRefOid", content) > 0).toBeTrue(
						"bot-address-review.yml must resolve the head SHA once at the "
						& "workflow level (via `gh pr view --json ...headRefOid`) so a stable "
						& "SHA can be threaded into the prompt — mirroring bot-advisor.yml "
						& "(issue ##2848 / PR ##2865)."
					);
				});

				it("threads the resolved head SHA into the /address-review command", () => {
					expect(fileExists(addressReview)).toBeTrue("Missing file: " & addressReview);
					var content = fileRead(addressReview);
					expect(
						reFindNoCase(
							"/address-review\s+\$\{\{\s*env\.PR_NUMBER\s*\}\}\s+\$\{\{\s*steps\.pr\.outputs\.sha\s*\}\}",
							content
						) > 0
					).toBeTrue(
						"bot-address-review.yml must pass ${{ steps.pr.outputs.sha }} into "
						& "the /address-review command so the implementer emits its "
						& "`wheels-bot:address-review:<pr>:<sha>:` markers from the resolved "
						& "head SHA (the head at run start, before its own commit), not a "
						& "re-derived `gh pr view` head (issue ##2848 / PR ##2865)."
					);
				});

			});

			describe("convergence-loop prompts emit the marker from the passed SHA", () => {

				// Each prompt must stop re-deriving the marker SHA from
				// `gh pr view --json headRefOid` (which races with pushes landing
				// mid-session) and instead use the <head-sha> the workflow now
				// passes as a command argument. Asserting headRefOid is gone is the
				// behavioral signal — and unlike the workflows (where resolving
				// headRefOid once at the step level is the fix), the prompts must
				// never query it at all. A bare `<head-sha>` substring check is not
				// used: it could false-pass on unrelated prose, whereas the absence
				// of headRefOid directly proves the re-derivation is gone.
				var prompts = [
					{path: repoRoot & "/.claude/commands/address-review.md", name: "address-review.md"},
					{path: repoRoot & "/.claude/commands/advise-on-deadlock.md", name: "advise-on-deadlock.md"}
				];

				for (var p in prompts) {
					// Capture the loop variable so the closure body binds the
					// current value, not the final iteration's value (CFML closures
					// capture by reference).
					(function(prompt) {
						it("no longer re-derives the SHA via `gh pr view --json headRefOid` in " & prompt.name, () => {
							expect(fileExists(prompt.path)).toBeTrue("Missing file: " & prompt.path);
							var content = fileRead(prompt.path);
							expect(reFindNoCase("headRefOid", content) > 0).toBeFalse(
								prompt.name & " must not derive the marker SHA from "
								& "`gh pr view --json headRefOid` — it races with pushes that "
								& "land between checkout and marker emission. Emit the marker "
								& "from the <head-sha> argument the workflow passes instead "
								& "(issue ##2848 / PR ##2865)."
							);
						});
					})(p);
				}

			});

		});

	}

}
