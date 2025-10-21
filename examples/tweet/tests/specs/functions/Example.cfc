component extends="wheels.Testbox" {
	function beforeAll(){
			// setup test data
	}
	function afterAll(){
			// clean up test data
	}

	function run() {

		describe("Tests that DummyTest", function() {

			it("is Returning True", function() {
				assert("true")
			})
			
		})
	}
}