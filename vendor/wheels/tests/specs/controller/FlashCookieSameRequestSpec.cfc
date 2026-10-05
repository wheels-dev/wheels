/**
 * Cookie flash storage, written and read in the same request (4433). The flash cookie
 * is set as an attribute struct; RustCFML reads such a cookie back in that request as
 * the struct, where Lucee, Adobe and BoxLang give its value. Over real HTTP, because
 * inside the test runner cookie flash goes through a request-scoped slot instead.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("cookie flash in the request that wrote it (4433)", () => {

			it("reads back the message flashInsert() just stored", () => {
				$testClient().get("/_flashcookie/insertread").assertOk().assertSee("notice=[saved]");
			});

		});

	}

}
