component extends="testbox.system.BaseSpec" {

	function run() {

		describe("Tests that onerror", () => {

			it("cfmlerror shows wheels templates", () => {
				try {
					Throw(type = "UnitTestError")
				} catch (any e) {
					exception = e
				}

				actual = application.wo.$includeAndReturnOutput($template = "/wheels/events/onerror/cfmlerror.cfm", exception = exception)

				system = CreateObject("java", "java.lang.System").getProperties()

				if(findNoCase('Windows', system['os.name'])){
					expected = "\wheels\core_tests\specs\events\onerror.cfc:9"
				}else {
					expected = "/wheels/core_tests/specs/events/onerror.cfc:9"
				}

				expect(actual).toInclude(expected)
			})
		})
	}
}
