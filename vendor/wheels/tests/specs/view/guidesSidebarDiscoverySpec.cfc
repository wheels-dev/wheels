component extends="wheels.WheelsTest" {

	// Regression guard for issue ##2647. The in-app Guides redirector at
	// vendor/wheels/public/docs/guides.cfm originally hardcoded
	//   /wheels/../../web/sites/guides/src/sidebars/v4-0-0-snapshot.json
	// as the source of its in-page sidebar listing. That filename was
	// removed when v4.0.0 went GA (the active dev snapshot is now
	// v4-0-1-snapshot.json), so contributors running Wheels from a fresh
	// monorepo checkout saw an empty sidebar — the FileExists() guard fell
	// through silently. The same hardcoded path lives in the AI summary
	// endpoint at vendor/wheels/public/views/ai.cfm. Both must resolve the
	// sidebar dynamically so the URL doesn't re-rot on the next
	// version bump.

	function run() {

		describe("Guides sidebar discovery", () => {

			it("docs/guides.cfm does not hardcode the retired v4-0-0-snapshot.json filename (regression for ##2647)", () => {
				var source = FileRead(ExpandPath("/wheels/public/docs/guides.cfm"));
				expect(source).notToInclude(
					"v4-0-0-snapshot.json",
					"docs/guides.cfm hardcoded a sidebar path to v4-0-0-snapshot.json; that file was removed when v4.0.0 went GA, so the in-app Guides page now renders an empty sidebar for monorepo contributors. Resolve the sidebar file dynamically instead (issue ##2647)."
				);
			});

			it("views/ai.cfm does not hardcode the retired v4-0-0-snapshot.json filename (regression for ##2647)", () => {
				var source = FileRead(ExpandPath("/wheels/public/views/ai.cfm"));
				expect(source).notToInclude(
					"v4-0-0-snapshot.json",
					"views/ai.cfm hardcoded a sidebar path to v4-0-0-snapshot.json; the AI summary endpoint returns an empty guides[] when that file is missing. Resolve the sidebar file dynamically instead (issue ##2647)."
				);
			});

			it("the monorepo sidebars directory ships at least one *.json the dynamic discovery can pick up", () => {
				var sidebarsDir = ExpandPath("/wheels/../../web/sites/guides/src/sidebars");
				if (!DirectoryExists(sidebarsDir)) {
					// Installed-app environment — no monorepo web/ tree on
					// disk. The discovery contract is "return [] silently",
					// not "find a sidebar". Skip without failing.
					return;
				}

				// Mirror the discovery logic that guides.cfm / ai.cfm use:
				// glob *.json under sidebars/ and sort basenames in
				// descending lexicographic order. The highest-named entry is
				// the latest snapshot (a "-snapshot" suffix sorts after the
				// matching GA, which is what we want — the dev snapshot wins
				// over a GA at the same version). The file must exist.
				var candidates = DirectoryList(sidebarsDir, false, "name", "*.json");
				expect(ArrayLen(candidates)).toBeGT(
					0,
					"web/sites/guides/src/sidebars/ must contain at least one *.json — without it the in-app Guides view has nothing to render."
				);
				ArraySort(candidates, "textnocase", "desc");
				var resolvedPath = sidebarsDir & "/" & candidates[1];
				expect(FileExists(resolvedPath)).toBeTrue(
					"Highest-versioned sidebar file must exist on disk; the discovery logic in docs/guides.cfm and views/ai.cfm relies on this."
				);
			});

		});

	}

}
