component extends="wheels.WheelsTest" {

	function run() {
		describe("debug bar page inset (expanded vs collapsed)", () => {
			// The bar is position:fixed at the bottom of the viewport. Without a
			// compensating inset, expanded chrome overlays page controls and
			// document scroll cannot reach that strip. These specs lock the
			// CSS/JS contract: reserve --wdb-inset on html while expanded,
			// collapse it to 0 when the logo strip is showing.

			it("reserves page padding for the expanded bar and releases it when collapsed", () => {
				var css = FileRead(ExpandPath("/wheels/public/assets/css/debugbar.css"));
				var js = FileRead(ExpandPath("/wheels/public/assets/js/debugbar.js"));

				expect(FindNoCase("--wdb-inset", css)).toBeGT(
					0,
					"debugbar.css must expose --wdb-inset so page content can sit above the bar"
				);
				expect(FindNoCase("padding-bottom:var(--wdb-inset)", css)).toBeGT(
					0,
					"debugbar.css must apply padding-bottom from --wdb-inset on the document"
				);
				expect(FindNoCase("scroll-padding-bottom:var(--wdb-inset)", css)).toBeGT(
					0,
					"debugbar.css must keep scroll-into-view above the reserved strip"
				);
				expect(FindNoCase(":has(##wheels-debugbar)", css)).toBeGT(
					0,
					"expanded inset must apply when ##wheels-debugbar is in the document"
				);
				expect(FindNoCase(":has(##wheels-debugbar.wdb-collapsed)", css)).toBeGT(
					0,
					"collapsed chrome must zero the inset via :has(.wdb-collapsed)"
				);
				expect(FindNoCase("--wdb-inset:0px", css)).toBeGT(
					0,
					"collapsed inset must be 0 so the logo strip does not leave a full-width dead zone"
				);
				expect(FindNoCase("wdb-has-debugbar", css)).toBeGT(
					0,
					"debugbar.css must keep a class fallback alongside :has() for the inset"
				);
				expect(FindNoCase("wdb-debugbar-collapsed", css)).toBeGT(
					0,
					"debugbar.css must zero the inset when html.wdb-debugbar-collapsed is set"
				);

				expect(FindNoCase("syncPageInset", js)).toBeGT(
					0,
					"debugbar.js must sync --wdb-inset when collapse state changes"
				);
				expect(FindNoCase("setProperty('--wdb-inset'", js)).toBeGT(
					0,
					"debugbar.js must write --wdb-inset on the document element"
				);
				expect(FindNoCase("wdb-debugbar-collapsed", js)).toBeGT(
					0,
					"debugbar.js must toggle html.wdb-debugbar-collapsed with the chrome class"
				);
			});
		});
	}

}
