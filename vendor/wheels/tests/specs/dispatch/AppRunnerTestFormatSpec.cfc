component extends="wheels.WheelsTest" {

	function run() {

		describe("app-runner output format resolution (issue 3251)", () => {

			// Issue #3251 (item 1): `/wheels/app/tests?format=html` — which is
			// also the no-format default — historically emitted application/json.
			// A user opening that URL in a browser reasonably expects the
			// TestBox-style HTML report the core runner (`/wheels/core/tests`)
			// renders. resolveFormat() centralizes the format-to-output decision
			// so the html / no-format branch can be marked rendersHtml=true; the
			// app runner then falls through to html.cfm (type="App", a branch
			// html.cfm already supports) exactly like the core runner does.
			//
			// Recognized formats are html | json | txt | junit (plus the
			// no-format default). An UNrecognized value (an empty string or an
			// arbitrary token like "xml") resolves to recognized=false: the app
			// runner emits nothing for it, preserving the historical behavior.
			// html.cfm must NOT be rendered for an arbitrary url.format — its
			// dev-tools navigation builds format-toggle links from url.format and
			// the framework's response content-negotiation 500s on Adobe when the
			// format is unknown.

			it("renders HTML when url has no format key (the no-format default)", () => {
				var resolver = new wheels.tests._assets.dispatch.TestFormatResolver();
				var resolved = resolver.resolveFormat(url = {});
				expect(resolved.recognized).toBeTrue();
				expect(resolved.rendersHtml).toBeTrue();
				expect(resolved.format).toBe("html");
				expect(resolved.contentType).toBe("text/html");
			});

			it("renders HTML for format=html", () => {
				var resolver = new wheels.tests._assets.dispatch.TestFormatResolver();
				var resolved = resolver.resolveFormat(url = { format: "html" });
				expect(resolved.recognized).toBeTrue();
				expect(resolved.rendersHtml).toBeTrue();
				expect(resolved.contentType).toBe("text/html");
			});

			it("uses the JSON reporter for the HTML branch (html.cfm needs the JSON payload to render)", () => {
				var resolver = new wheels.tests._assets.dispatch.TestFormatResolver();
				expect(resolver.resolveFormat(url = { format: "html" }).reporter)
					.toBe("wheels.wheelstest.system.reports.JSONReporter");
			});

			it("emits JSON (not HTML) for format=json", () => {
				var resolver = new wheels.tests._assets.dispatch.TestFormatResolver();
				var resolved = resolver.resolveFormat(url = { format: "json" });
				expect(resolved.recognized).toBeTrue();
				expect(resolved.rendersHtml).toBeFalse();
				expect(resolved.format).toBe("json");
				expect(resolved.contentType).toBe("application/json");
				expect(resolved.reporter).toBe("wheels.wheelstest.system.reports.JSONReporter");
			});

			it("emits text/plain for format=txt via the Text reporter", () => {
				var resolver = new wheels.tests._assets.dispatch.TestFormatResolver();
				var resolved = resolver.resolveFormat(url = { format: "txt" });
				expect(resolved.recognized).toBeTrue();
				expect(resolved.rendersHtml).toBeFalse();
				expect(resolved.format).toBe("txt");
				expect(resolved.contentType).toBe("text/plain");
				expect(resolved.reporter).toBe("wheels.wheelstest.system.reports.TextReporter");
			});

			it("emits text/xml for format=junit via the ANTJUnit reporter", () => {
				var resolver = new wheels.tests._assets.dispatch.TestFormatResolver();
				var resolved = resolver.resolveFormat(url = { format: "junit" });
				expect(resolved.recognized).toBeTrue();
				expect(resolved.rendersHtml).toBeFalse();
				expect(resolved.format).toBe("junit");
				expect(resolved.contentType).toBe("text/xml");
				expect(resolved.reporter).toBe("wheels.wheelstest.system.reports.ANTJUnitReporter");
			});

			it("matches the format token case-insensitively", () => {
				var resolver = new wheels.tests._assets.dispatch.TestFormatResolver();
				expect(resolver.resolveFormat(url = { format: "JSON" }).format).toBe("json");
				expect(resolver.resolveFormat(url = { format: "Txt" }).format).toBe("txt");
				expect(resolver.resolveFormat(url = { format: "HTML" }).rendersHtml).toBeTrue();
			});

			it("trims surrounding whitespace before matching", () => {
				var resolver = new wheels.tests._assets.dispatch.TestFormatResolver();
				expect(resolver.resolveFormat(url = { format: "  junit  " }).format).toBe("junit");
			});

			it("does NOT render HTML for an empty format value (preserves the historical no-output behavior)", () => {
				var resolver = new wheels.tests._assets.dispatch.TestFormatResolver();
				var resolved = resolver.resolveFormat(url = { format: "" });
				expect(resolved.recognized).toBeFalse();
				expect(resolved.rendersHtml).toBeFalse();
			});

			it("does NOT render HTML for an unrecognized format token (avoids the Adobe html.cfm 500)", () => {
				// Rendering html.cfm for an arbitrary url.format 500s on Adobe
				// (the dev-tools nav reads url.format and response negotiation
				// chokes on the unknown format). An unrecognized token must
				// resolve to recognized=false so the app runner emits nothing,
				// exactly as it did before this fix.
				var resolver = new wheels.tests._assets.dispatch.TestFormatResolver();
				var resolved = resolver.resolveFormat(url = { format: "xml" });
				expect(resolved.recognized).toBeFalse();
				expect(resolved.rendersHtml).toBeFalse();
			});

		});

	}

}
