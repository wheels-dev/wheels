component extends="wheels.WheelsTest" {

	function run() {

		describe("Guides redirect view", () => {

			// Convention guard for issue #2569. The wrapper view
			// vendor/wheels/public/views/guides.cfm includes
			// ../layout/_header.cfm before ../docs/guides.cfm, so by the
			// time the rendered docs view runs the response has already
			// streamed past </head>. The previous implementation injected
			// the 3-second redirect meta tag with cfhtmlhead, which Lucee
			// tolerates but Adobe ColdFusion rejects with "Unable to add
			// text to HTML HEAD tag." This test ensures the docs view does
			// not regress back to cfhtmlhead. The body-level redirect
			// reads its target from a data attribute so the docs.url value
			// only ever flows through encodeForHTMLAttribute, the same
			// encoder used by the visible link in the same view.
			it("does not use cfhtmlhead — adobe cf errors when content is added to the html head after the layout has already streamed", () => {
				var source = FileRead(ExpandPath("/wheels/public/docs/guides.cfm"));
				// Strip CFML comments first so explanatory mentions of the
				// banned tag in inline documentation do not trip the guard.
				// The body uses [\s\S]*? to match across newlines because
				// the CFML/Java regex dot does not match line terminators
				// by default; [\s\S] is the portable any-character idiom.
				source = reReplace(source, "<!---[\s\S]*?--->", "", "all");
				// Build the cfhtmlhead pattern with Chr(60) so the spec
				// source never carries a literal opening angle-bracket
				// CFML tag in a string. The same defensive convention is
				// already used by MigratorViewIconsSpec.cfc, which builds
				// its <svg / <i icon regexes the same way. The framework
				// test runner compiles every CFC under tests.specs.* on
				// load, so a malformed CFC takes the whole suite down
				// for the engine — keeping these patterns in Chr(60)
				// form sidesteps that whole class of failure.
				var pattern = Chr(60) & "cfhtmlhead\b";
				var hits = reMatchNoCase(pattern, source);
				expect(ArrayLen(hits)).toBe(
					0,
					"docs/guides.cfm must not use cfhtmlhead — see issue ##2569. The wrapper view emits the layout header before this view runs, so </head> has already streamed by the time cfhtmlhead executes. Emit the redirect inline in the body instead."
				);
			});

			// Companion check: the redirect mechanism must still exist,
			// even though it now lives in the body. If someone removes the
			// cfhtmlhead in response to #2569 but forgets to add a
			// replacement, the page will stop redirecting silently. This
			// guards against that regression by checking for either a
			// JavaScript-based redirect or an explicit data-url hook.
			it("emits a body-level redirect to guides.wheels.dev", () => {
				var source = FileRead(ExpandPath("/wheels/public/docs/guides.cfm"));
				expect(source).toInclude(
					"window.location.href",
					"docs/guides.cfm must redirect HTML callers to guides.wheels.dev. The legacy cfhtmlhead approach broke on Adobe CF (##2569); replace it with a body-level redirect that reads its target via JavaScript."
				);
			});

		});

	}

}
