component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("autoLink protocol handling", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("does not prefix absolute URLs that follow a www-form URL", () => {
				result = _controller.autoLink(
					text = "Visit www.wheels.dev and https://guides.wheels.dev today",
					encode = false
				)
				expect(result).toInclude('<a href="http://www.wheels.dev">www.wheels.dev</a>')
				expect(result).toInclude('<a href="https://guides.wheels.dev">https://guides.wheels.dev</a>')
				expect(result).notToInclude("http://https://")
			})
		})

		describe("$paramsToQueryString", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("builds a query string from a simple struct", () => {
				paramsStruct = {}
				paramsStruct["page"] = 2
				result = _controller.$paramsToQueryString(paramsStruct)
				expect(result).toBe("page=2")
			})

			it("URL-encodes both keys and values", () => {
				paramsStruct = {}
				paramsStruct["a&b"] = "c=d"
				result = _controller.$paramsToQueryString(paramsStruct)
				expect(result).toBe("a%26b=c%3Dd")
			})
		})

		describe("$tag addClass handling", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("uses addClass as the class attribute when no class attribute exists", () => {
				args = {}
				args.name = "input"
				args.attributes = {}
				args.attributes["type"] = "text"
				args.attributes["addClass"] = "newClass"
				result = _controller.$tag(argumentCollection = args)
				expect(result).toBe('<input class="newClass" type="text">')
			})
		})

		describe("$getValueByDynamicPath", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("resolves bracket-quoted segments containing non-word characters", () => {
				inner = {}
				inner["my-key"] = "hello"
				pathScope = {}
				pathScope["obj"] = inner
				result = _controller.$getValueByDynamicPath("obj['my-key']", pathScope)
				expect(result).toBe("hello")
			})

			it("still resolves multi-segment paths with array indexes", () => {
				inner = {}
				inner["items"] = ["a", "b", "c"]
				pathScope = {}
				pathScope["obj"] = inner
				result = _controller.$getValueByDynamicPath("obj['items'][2]", pathScope)
				expect(result).toBe("b")
			})

			it("throws Wheels.ObjectNotFound instead of invoking when a struct segment is missing", () => {
				state = {errorType = ""}
				pathScope = {}
				pathScope["obj"] = {}
				try {
					_controller.$getValueByDynamicPath("obj['missing']", pathScope)
				} catch (any e) {
					state.errorType = e.type
				}
				expect(state.errorType).toBe("Wheels.ObjectNotFound")
			})
		})

		describe("flashMessages with absent keys", () => {

			beforeEach(() => {
				_params = {controller = "dummy", action = "dummy"}
				_controller = g.controller("dummy", _params)
				_controller.$setFlashStorage("session")
				_controller.flashClear()
			})

			afterEach(() => {
				_controller.flashClear()
			})

			it("returns an empty string instead of throwing when the requested key was never flashed", () => {
				result = _controller.flashMessages(key = "error", encode = false)
				expect(result).toBe("")
			})

			it("renders present keys and skips absent ones from a key list", () => {
				_controller.flashInsert(success = "Saved!")
				result = _controller.flashMessages(keys = "success,error", encode = false)
				expect(result).toInclude("Saved!")
				expect(result).notToInclude("error-message")
			})
		})

		describe("highlight with degenerate phrase input", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("returns the text unchanged when the phrase list collapses to an empty array", () => {
				result = _controller.highlight(text = "Some text", phrase = ",", encode = false)
				expect(result).toBe("Some text")
			})
		})

		describe("$decodeHtmlEntities range cap", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("leaves overlong numeric entities untouched instead of crashing", () => {
				input = "&##x7FFFFFFFFF;abc&##999999999999;def"
				result = _controller.$decodeHtmlEntities(input)
				expect(result).toBe(input)
			})

			it("leaves the just-out-of-range code point 0x110000 untouched", () => {
				result = _controller.$decodeHtmlEntities("&##x110000;")
				expect(result).toBe("&##x110000;")
			})

			it("still decodes valid decimal and hex entities", () => {
				result = _controller.$decodeHtmlEntities("&##65;&##x42;")
				expect(result).toBe("AB")
			})
		})
	}
}
