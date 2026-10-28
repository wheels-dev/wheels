/**
 * Regression for #4638: $toXml() is declared `xml`, so it cannot return an empty
 * string for a null root value. On engines that can hold/accept null it must
 * return a well-formed null document; engines that cannot pass a null to a
 * required argument (Lucee with null support off, RustCFML) skip the assertion.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("$toXml root null (##4638)", () => {

			it("renders a root-level null as a well-formed null document", () => {
				// Probe null-argument support with an unrelated helper, never with $toXml: on a
				// null-capable engine a regression in $toXml must fail this spec, not be caught
				// and turned into a skip.
				if (!$canPassNullArgument()) {
					skip("engine cannot pass a null to a required argument (Lucee null support off, RustCFML)")
				}
				var output = g.$toXml(javaCast("null", ""))
				expect(output).toBeXML()
				expect(FindNoCase('type="null"', output)).toBeGT(0, "missing null element in [#output#]")
			})

			it("declares a well-formed null document for the root-null branch", () => {
				// Runs on every engine, including the ones that skip the live call above: an
				// xml-typed function must never return an empty string from this branch.
				var source = FileRead(ExpandPath("/wheels/global/util.cfm"))
				expect(Find('<?xml version="1.0" encoding="UTF-8"?><data type="null"/>', source)).toBeGT(
					0,
					"$toXml must return a well-formed null document for a root-level null"
				)
			})

		})

	}

	/** True when the engine can pass a null to a required argument. */
	private boolean function $canPassNullArgument() {
		try {
			$acceptsNullArg(javaCast("null", ""))
		} catch (any e) {
			return false
		}
		return true
	}

	/** Tiny probe target: only used to detect null-argument support. */
	private boolean function $acceptsNullArg(required any value) {
		return IsNull(arguments.value)
	}

}
