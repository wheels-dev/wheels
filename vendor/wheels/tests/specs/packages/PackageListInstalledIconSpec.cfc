/**
 * Tools > Packages page (#2423): the "Installed" badge on registry rows must
 * use an inline SVG checkmark, not Semantic UI's icon font.
 *
 * The bundled `vendor/wheels/public/assets/css/semantic.min.css` is inlined
 * into the page via a script-side include inside a style block in
 * `_header.cfm`, which breaks the @font-face `url(themes/default/assets/`
 * `fonts/icons.*)` relative paths (they resolve against the page URL, not
 * the CSS file location). Additionally the `Icons` font-face declaration
 * in that bundle only references `.eot` and `.svg` formats — no `.woff` or
 * `.woff2` — so even with working URLs no modern browser can load the
 * glyph. Every other icon in the same view uses inline SVG; the Installed
 * badge must do the same.
 */
component extends="wheels.WheelsTest" {

	function run() {
		describe("packagelist.cfm Installed badge (##2423)", () => {

			it("does not use Semantic UI's icon font for the Installed badge", () => {
				var source = FileRead(ExpandPath("/wheels/public/views/packagelist.cfm"));

				expect(FindNoCase("<i class=""check icon"">", source) GT 0).toBeFalse(
					"packagelist.cfm must not use <i class=""check icon""></i> for "
					& "the Installed badge — the Semantic UI icon font is not "
					& "loadable in this view (CSS is inlined, breaking relative "
					& "@font-face URLs, and the bundle omits .woff/.woff2 for the "
					& "Icons family). Use an inline <svg> checkmark instead."
				);
			});

			it("renders the Installed badge with an inline SVG checkmark", () => {
				var source = FileRead(ExpandPath("/wheels/public/views/packagelist.cfm"));

				// The Installed badge block: a <span class="ui label"> that
				// contains an <svg>...</svg> followed by the word "Installed".
				// Tolerate whitespace and arbitrary svg attributes/contents.
				var pattern = "<span[^>]*class=""[^""]*ui[^""]*label[^""]*""[^>]*>\s*<svg[\s\S]*?</svg>\s*Installed";

				expect(REFindNoCase(pattern, source) GT 0).toBeTrue(
					"Expected a <span class=""ui label""> containing an inline "
					& "<svg>...</svg> immediately before the text 'Installed'. "
					& "See issue ##2423."
				);
			});

		});
	}

}
