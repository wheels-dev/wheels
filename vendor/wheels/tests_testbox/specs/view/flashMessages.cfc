component extends="testbox.system.BaseSpec" {

	function beforeAll() {
		params = {controller = "dummy", action = "dummy"}
		_controller = application.wo.controller("dummy", params)
		application.wo.set(functionName = "flashMessages", encode = false)
	}
	
	function afterAll() {
		application.wo.set(functionName = "flashMessages", encode = true)
	}

	function run() {

		describe("Tests that flashMessages", () => {

			beforeEach(() => {
				_controller.$setFlashStorage("session")
				_controller.flashClear()
			})

			afterEach(() => {
				_controller.flashClear()
			})

			it("encodes HTML in flashMessages when encode=true", () => {
				_controller.flashInsert(error = "Error with <strong>bold</strong> text")
				actual = _controller.flashMessages(encode = true)
				expected = '<div class="flash-messages"><p class="error-message">Error with &lt;strong&gt;bold&lt;&##x2f;strong&gt; text</p></div>'
				
				expect(actual).toBe(expected)
			})
			
			it("does not encode HTML in flashMessages when encode=false", () => {
				_controller.flashInsert(error = "Error with <strong>bold</strong> text")
				actual = _controller.flashMessages(encode = false)
				expected = '<div class="flash-messages"><p class="error-message">Error with <strong>bold</strong> text</p></div>'
				
				expect(actual).toBe(expected)
			})
			
			it("handles array values with proper encoding", () => {
				arr = []
				arr[1] = "Error with <strong>bold</strong> text"
				arr[2] = "Another error with <em>emphasis</em>"
				_controller.flashInsert(error = arr)
				
				// Test with encode=true
				actual = _controller.flashMessages(encode = true)

				expect(actual).toInclude('Error with &lt;strong&gt;bold&lt;&##x2f;strong&gt; text')
				expect(actual).toInclude('Another error with &lt;em&gt;emphasis&lt;&##x2f;em&gt;')
				
				// Test with encode=false
				_controller.flashClear()
				_controller.flashInsert(error = arr)
				actual = _controller.flashMessages(encode = false)

				expect(actual).toInclude('Error with <strong>bold</strong> text')
				expect(actual).toInclude('Another error with <em>emphasis</em>')
			})
		})
	}
}