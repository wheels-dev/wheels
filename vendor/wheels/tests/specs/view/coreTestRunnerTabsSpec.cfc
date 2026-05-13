component extends="wheels.WheelsTest" {

	// Regression guard for issue #2651. When running the complete Wheels core
	// test suite, the result page's "Failures / Errors / Passed" tabs render
	// as static, non-interactive HTML — only the default-active tab is
	// reachable. The activator JS (`$('.menu .item').tab();`) lives in
	// `vendor/wheels/public/layout/_footer.cfm`, which is included from
	// `vendor/wheels/tests/html.cfm` at the very end of the cfoutput block.
	// On the full-suite path the response between the tab markup and the
	// footer include is large enough that — depending on engine, buffer
	// state, and JSONReporter's resetHTMLResponse() side effects — the
	// footer's script does not always reach the browser. Single-test
	// runs render a tiny page and never hit the regression, which is why
	// it slipped through.
	//
	// The defensive fix is to stop relying on _footer.cfm for tab init on
	// this page: html.cfm must initialize the tabs itself, inline, right
	// after the menu markup. Then tab switching works regardless of whether
	// the footer reaches the browser.

	function run() {

		describe("Core test runner result page", () => {

			it("initializes Semantic UI tabs inline so tab switching works even if _footer.cfm is truncated (regression for ##2651)", () => {
				var src = fileRead(expandPath("/wheels/tests/html.cfm"));
				// Match the exact JS call as it appears in the <script> block.
				// This string does NOT appear in any CFML comment, so passing this
				// assertion proves the executable script block is present — not
				// just narrative comment text describing the fix.
				expect(findNoCase("jQuery('.menu .item').tab()", src) GT 0).toBeTrue(
					"html.cfm must invoke jQuery('.menu .item').tab() in an inline script block (not via _footer.cfm). See issue ##2651."
				);
			});

			it("places the inline tab initializer immediately after the tab menu so a downstream rendering failure cannot strip it (regression for ##2651)", () => {
				var src = fileRead(expandPath("/wheels/tests/html.cfm"));
				var menuPos = findNoCase("tabular menu stackable", src);
				var tabCallPos = findNoCase(".tab()", src);
				expect(menuPos GT 0).toBeTrue("Tab menu markup should still be present in html.cfm.");
				expect(tabCallPos GT 0).toBeTrue("Inline tab initializer should be present in html.cfm.");
				expect(tabCallPos GT menuPos).toBeTrue(
					"Inline tab initializer must appear after the menu markup so it can bind to it. See issue ##2651."
				);
			});

		});

	}

}
