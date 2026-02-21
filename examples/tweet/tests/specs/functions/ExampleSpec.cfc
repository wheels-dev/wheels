component extends="wheels.WheelsTest" {
	function beforeAll(){
			// setup test data
	}
	function afterAll(){
			// clean up test data
	}

	function run() {

		describe("Tests that DummyTest", function() {

			it("is Returning True", function() {
				expect("true").toBeTrue()
			})
			
		})
	}
}