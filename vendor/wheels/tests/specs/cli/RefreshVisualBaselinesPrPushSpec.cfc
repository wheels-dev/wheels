component extends="wheels.WheelsTest" {

	// Regression for issue ##3283.
	//
	// The final "Commit and push refreshed baselines" step in
	// .github/workflows/refresh-visual-baselines.yml pushed the refreshed PNG(s)
	// straight back to the dispatched branch with `git push origin "HEAD:$BRANCH"`.
	// Once the `develop` branch ruleset started requiring "Changes must be made
	// through a pull request", that direct push is rejected with
	// `GH013: Repository rule violations found` and the workflow fails after doing
	// all the expensive rebuild + screenshot work.
	//
	// The fix extracts delivery into tools/gh-open-refresh-baseline-pr.sh:
	//   1. Commit the refreshed PNG(s), then try the direct push as a GUARDED
	//      fast path. On an unprotected branch (the workflow header's documented
	//      flow — dispatching on a PR's source branch) this keeps the exact
	//      pre-##3283 behaviour: the commit lands immediately.
	//   2. If the push is rejected (GH013 on develop), fall back to a throwaway
	//      `chore/refresh-baseline-*` branch + `gh pr create` against the target
	//      branch. That needs `pull-requests: write` on the job (a
	//      direct-push-only job only has `contents: write`).
	//   3. The fallback PR is deliberately NOT auto-merged: it is authored by
	//      the workflow's GITHUB_TOKEN, and GitHub never fires `pull_request`
	//      workflows for GITHUB_TOKEN-authored PRs, so the target branch's
	//      required checks would sit "Expected" forever and auto-merge would
	//      wedge silently. The sibling refresh-packages-baseline.yml documents
	//      the same gotcha and also leaves its PR for a human.
	//
	// Because the step's behaviour (git + gh side effects against a real
	// checkout) cannot be exercised in a unit test, this spec pins the invariant
	// with a static check of the workflow and the helper it calls. Whole-line
	// shell/YAML comments are stripped first so the assertions only match
	// EXECUTABLE code — a comment that merely mentions `gh pr create` must not
	// satisfy the spec.

	function run() {

		describe("refresh-visual-baselines.yml survives a push-protected branch (issue ##3283)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var workflow = repoRoot & "/.github/workflows/refresh-visual-baselines.yml";
			var helper = repoRoot & "/tools/gh-open-refresh-baseline-pr.sh";

			// Drop whole-line comments (`   ## ...` in shell and YAML alike) so
			// the it-blocks assert on executable lines only. Line-by-line filter
			// on purpose — no global regex over the whole file.
			var stripCommentLines = function(required string src) {
				var lines = listToArray(src, chr(10), true);
				var kept = [];
				for (var line in lines) {
					if (!reFind("^[ \t]*##", line)) {
						arrayAppend(kept, line);
					}
				}
				return arrayToList(kept, chr(10));
			};

			it("hosts no push of its own — the workflow delegates delivery to the tools/ helper", () => {
				expect(fileExists(workflow)).toBeTrue("Missing file: " & workflow);
				var wfExec = stripCommentLines(fileRead(workflow));

				// The classic direct push the develop ruleset rejects lived in a
				// workflow `run:` block:  git push origin "HEAD:$BRANCH"
				// No `git push` of any shape belongs in the workflow now.
				expect(reFindNoCase("git[[:space:]]+push", wfExec) == 0).toBeTrue(
					"issue ##3283: refresh-visual-baselines.yml must NOT push from a workflow "
					& "step (`git push origin ""HEAD:$BRANCH""` is what the develop ruleset "
					& "rejects with GH013). Delivery belongs in "
					& "tools/gh-open-refresh-baseline-pr.sh, which guards the push and falls "
					& "back to a PR."
				);
				expect(reFindNoCase("gh-open-refresh-baseline-pr\.sh", wfExec) > 0).toBeTrue(
					"issue ##3283: refresh-visual-baselines.yml must invoke "
					& "tools/gh-open-refresh-baseline-pr.sh to deliver the refreshed baseline(s)."
				);
			});

			it("grants the job pull-requests: write so the PR fallback can operate", () => {
				var wfExec = stripCommentLines(fileRead(workflow));
				expect(reFindNoCase("pull-requests:[[:space:]]*write", wfExec) > 0).toBeTrue(
					"issue ##3283: opening the fallback refresh PR needs `pull-requests: write` "
					& "in the job `permissions:` block. Without it the `gh pr create` call "
					& "fails on the default `contents: write`-only token."
				);
			});

			it("treats the direct push as a guarded fast path — a GH013 rejection can never fail the job", () => {
				expect(fileExists(helper)).toBeTrue(
					"Missing helper: " & helper & " — the commit/push/PR-fallback flow should "
					& "live in a reviewable, reusable script the workflow calls."
				);
				var helperExec = stripCommentLines(fileRead(helper));

				// Every executable `git push ... HEAD:<target>` must sit in an
				// `if` condition (rejection falls through to the PR fallback
				// instead of tripping `set -e`), and the fast path must exist.
				var pushLines = [];
				for (var line in listToArray(helperExec, chr(10), true)) {
					if (reFindNoCase("git[[:space:]]+push[^\n]*HEAD:", line)) {
						arrayAppend(pushLines, line);
					}
				}
				expect(arrayLen(pushLines) > 0).toBeTrue(
					"issue ##3283: the helper should keep the pre-##3283 direct push as a "
					& "fast path for branches that allow it (feature-branch dispatch, the "
					& "workflow header's documented flow)."
				);
				for (var pushLine in pushLines) {
					expect(reFindNoCase("^[ \t]*if[[:space:]]+git[[:space:]]+push", pushLine) > 0).toBeTrue(
						"issue ##3283: every direct `git push ... HEAD:<target>` in the helper "
						& "must be `if`-guarded so a ruleset rejection (GH013) falls through to "
						& "the PR fallback instead of failing the job under `set -e`. "
						& "Unguarded line: " & pushLine
					);
				}
			});

			it("falls back to an executable `gh pr create` and never enables auto-merge", () => {
				var helperExec = stripCommentLines(fileRead(helper));
				var wfExec = stripCommentLines(fileRead(workflow));

				expect(reFindNoCase("gh[[:space:]]+pr[[:space:]]+create", helperExec) > 0).toBeTrue(
					"issue ##3283: when the direct push is rejected, the refreshed baseline(s) "
					& "must be delivered via `gh pr create` against the target branch (executable "
					& "code, not a comment)."
				);

				// GITHUB_TOKEN-authored PRs never trigger `pull_request` workflows
				// (GitHub's recursive-trigger guard), so the required checks would
				// sit ""Expected"" forever and `gh pr merge --auto` would wedge
				// silently — the exact trap refresh-packages-baseline.yml documents.
				var combined = helperExec & chr(10) & wfExec;
				expect(reFindNoCase("gh[[:space:]]+pr[[:space:]]+merge[^\n]*--auto", combined) == 0).toBeTrue(
					"issue ##3283: do not enable auto-merge on the fallback refresh PR. It is "
					& "authored by the workflow's GITHUB_TOKEN, whose PRs never fire the "
					& "required `pull_request` checks, so auto-merge can never complete — the "
					& "PR must be left for a maintainer (see refresh-packages-baseline.yml's "
					& "header for the same gotcha)."
				);
			});

			it("keeps re-runs safe by seeding the throwaway branch name with the run attempt", () => {
				var helperExec = stripCommentLines(fileRead(helper));
				expect(reFindNoCase("chore/refresh-baseline-[^\n]*RUN_ID[^\n]*RUN_ATTEMPT", helperExec) > 0).toBeTrue(
					"issue ##3283: the throwaway branch name must include both RUN_ID and "
					& "RUN_ATTEMPT — a re-run of a failed job reuses the same run id, so a "
					& "branch named only after RUN_ID collides with the leftover branch from "
					& "attempt 1 and the `git push -u origin` fails non-fast-forward."
				);
			});

		});

	}

}
