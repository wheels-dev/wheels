component extends="wheels.WheelsTest" {

	// Regression guard for issue #2428. The "View Tests" link on the
	// Tools > Packages listing page (vendor/wheels/public/views/packagelist.cfm)
	// previously built its URL by string-concatenating `&directory=...` onto
	// the output of `urlFor(route='testbox')`. Because urlFor() returns a
	// clean path with no trailing `?`, the `&` ended up inside the path
	// segment ("/wheels/core/tests&directory=...") and the router rejected
	// the request with "Could not find a route that matched this request."
	//
	// The fix is to pass the directory through `urlFor`'s `params` argument
	// so the framework formats the query string correctly. This spec asserts
	// the structural invariant by reading the template source.

	function run() {

		describe("packagelist.cfm View Tests link", () => {

			it("does not concatenate '&directory=' onto urlFor() output (regression for ##2428)", () => {
				var src = fileRead(expandPath("/wheels/public/views/packagelist.cfm"));
				// The broken pattern is the literal sequence that places `&` in
				// the path segment. If anyone reintroduces it, the router will
				// 404 again exactly as reported.
				var brokenFragment = "urlFor(route='testbox')##&directory=";
				expect(findNoCase(brokenFragment, src) GT 0).toBeFalse(
					"packagelist.cfm must not concatenate '&directory=' onto urlFor() output. Pass the directory via urlFor's params argument instead. See issue ##2428."
				);
			});

			it("uses urlFor's params argument to pass the directory", () => {
				var src = fileRead(expandPath("/wheels/public/views/packagelist.cfm"));
				// The corrected pattern mirrors packageentry.cfm: directory is
				// passed via `params=` so urlFor() emits a well-formed
				// `?directory=...` query string.
				expect(findNoCase("urlFor(route='testbox', params='directory=", src) GT 0).toBeTrue(
					"packagelist.cfm should build the View Tests URL via urlFor(route='testbox', params='directory=...')."
				);
			});

		});

	}

}
