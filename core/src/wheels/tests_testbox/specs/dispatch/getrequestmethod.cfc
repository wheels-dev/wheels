component extends="testbox.system.BaseSpec" {
	
	function run() {

		describe("Tests that $getrequestmethod", () => {

			beforeEach(() => {
				_originalForm = Duplicate(form)
				_originalUrl = Duplicate(url)
				_originalCgiMethod = request.cgi.request_method
				StructClear(form)
				StructClear(url)
				d = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init")
			})

			afterEach(() => {
				StructClear(form)
				StructClear(url)
				StructAppend(form, _originalForm, false)
				StructAppend(url, _originalUrl, false)
				request.cgi["request_method"] = _originalCgiMethod
			})

			it("is getting GET request", () => {
				request.cgi["request_method"] = "GET"
				method = d.$getRequestMethod()

				expect(method).toBe("GET")
			})

			// https://github.com/cfwheels/cfwheels/issues/886
			it("should not override in GET request", () => {
				request.cgi["request_method"] = "GET"
				url._method = "delete"
				method = d.$getRequestMethod()

				expect(method).toBe("GET")
			})

			it("should not override in GET request in form", () => {
				request.cgi["request_method"] = "GET"
				form._method = "delete"
				method = d.$getRequestMethod()

				expect(method).toBe("GET")
			})

			it("is getting POST request", () => {
				request.cgi["request_method"] = "POST"
				method = d.$getRequestMethod()

				expect(method).toBe("POST")
			})

			it("overrides in POST request", () => {
				request.cgi["request_method"] = "POST"
				form._method = "PUT"
				method = d.$getRequestMethod()

				expect(method).toBe("PUT")
			})

			it("should not override in POST request in url", () => {
				request.cgi["request_method"] = "POST"
				url._method = "PUT"
				method = d.$getRequestMethod()

				expect(method).toBe("POST")
			})
		})
	}
}