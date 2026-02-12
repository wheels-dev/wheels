component extends="wheels.Testbox" {
	function beforeAll(){
			// setup test data
	}
	function afterAll(){
			// clean up test data
	}

	function run() {

		describe("Tests that DummyTest 1", function() {

			it("is Returning True 1", function() {
				expect("true").toBeTrue()
			})
			
		})

		describe("Tests that DummyTest 2", function() {

			it("is Returning True 2", function() {
				expect("true").toBeTrue()
			})
			
		})
	}
}