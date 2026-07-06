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
	// The fix converts the final step to the PR + auto-merge pattern already used
	// by the sibling .github/workflows/refresh-packages-baseline.yml: commit onto a
	// throwaway `chore/refresh-baseline-*` branch, `gh pr create` against the
	// target branch, and `gh pr merge --auto --squash --delete-branch`. That path
	// also needs `pull-requests: write` on the job (a direct-push-only job only
	// has `contents: write`, and the missing scope fails silently), and the PR
	// title must stay a valid conventional commit <=100 chars so the
	// "Validate Commit Messages" required check passes.
	//
	// The branch/commit/PR/auto-merge flow was extracted into
	// tools/gh-open-refresh-baseline-pr.sh so it is a real, reviewable
	// implementation artifact; the workflow now invokes it. Because the step's
	// behaviour (git + gh side effects against a real checkout) cannot be
	// exercised in a unit test, this spec pins the invariant with a static check
	// of the workflow and the helper it calls.

	function run() {

		describe("refresh-visual-baselines.yml pushes through a PR, not a direct push (issue ##3283)", () => {

			// expandPath("/wheels") resolves to vendor/wheels via the configured
			// Lucee mapping; the repo root is two levels above.
			var repoRoot = expandPath("/wheels/../..");
			var workflow = repoRoot & "/.github/workflows/refresh-visual-baselines.yml";
			var helper = repoRoot & "/tools/gh-open-refresh-baseline-pr.sh";

			it("no longer pushes the refreshed baseline commit directly to the dispatched branch", () => {
				expect(fileExists(workflow)).toBeTrue("Missing file: " & workflow);
				var wfSrc = fileRead(workflow);

				// The classic direct push the develop ruleset rejects:
				//   git push origin "HEAD:$BRANCH"
				// Any `git push ... HEAD:<target>` reproduces the GH013 rejection.
				var directPush = reFindNoCase("git[[:space:]]+push[^\n]*HEAD:", wfSrc);
				expect(directPush == 0).toBeTrue(
					"issue ##3283: refresh-visual-baselines.yml must NOT push the refreshed "
					& "baseline commit straight to the dispatched branch (`git push origin "
					& """HEAD:$BRANCH""`) — the develop ruleset rejects it with GH013. Route the "
					& "commit through a PR + auto-merge instead."
				);
			});

			it("grants the job pull-requests: write so gh pr create/merge can operate", () => {
				var wfSrc = fileRead(workflow);
				expect(reFindNoCase("pull-requests:[[:space:]]*write", wfSrc) > 0).toBeTrue(
					"issue ##3283: opening and auto-merging the refresh PR needs "
					& "`pull-requests: write` in the job `permissions:` block. Without it the "
					& "`gh pr create` / `gh pr merge` calls fail silently on the default "
					& "`contents: write`-only token."
				);
			});

			it("opens a PR and auto-merges it (matching refresh-packages-baseline.yml)", () => {
				var wfSrc = fileRead(workflow);

				// The flow may live inline in the workflow or in a helper the workflow
				// invokes; assert on the combined text so the spec is not brittle
				// about where the logic is hosted.
				var combined = wfSrc;
				if (fileExists(helper)) {
					combined = combined & chr(10) & fileRead(helper);
				}

				expect(reFindNoCase("gh[[:space:]]+pr[[:space:]]+create", combined) > 0).toBeTrue(
					"issue ##3283: the refreshed baseline(s) must be delivered via `gh pr create` "
					& "against the target branch, not a direct push."
				);
				expect(reFindNoCase("gh[[:space:]]+pr[[:space:]]+merge[^\n]*--auto", combined) > 0).toBeTrue(
					"issue ##3283: the refresh PR must enable auto-merge (`gh pr merge --auto`) so "
					& "it lands without a human round-trip once the required checks pass."
				);
			});

			it("delegates to the tools/ helper that implements the PR + auto-merge flow", () => {
				expect(fileExists(helper)).toBeTrue(
					"Missing helper: " & helper & " — the branch/commit/PR/auto-merge flow should "
					& "live in a reviewable, reusable script the workflow calls."
				);
				var helperSrc = fileRead(helper);

				// The helper commits onto a throwaway branch and pushes THAT branch
				// (never HEAD:<target>), then opens the PR.
				expect(reFindNoCase("git[[:space:]]+push[^\n]*HEAD:", helperSrc) == 0).toBeTrue(
					"issue ##3283: the helper must push its own throwaway branch, never "
					& "`git push ... HEAD:<target>` back to the protected branch."
				);
				expect(reFindNoCase("gh[[:space:]]+pr[[:space:]]+create", helperSrc) > 0).toBeTrue(
					"The helper should open the refresh PR with `gh pr create`."
				);

				// The workflow must actually call the helper.
				var wfSrc = fileRead(workflow);
				expect(reFindNoCase("gh-open-refresh-baseline-pr\.sh", wfSrc) > 0).toBeTrue(
					"issue ##3283: refresh-visual-baselines.yml must invoke "
					& "tools/gh-open-refresh-baseline-pr.sh to open the refresh PR."
				);
			});

		});

	}

}
