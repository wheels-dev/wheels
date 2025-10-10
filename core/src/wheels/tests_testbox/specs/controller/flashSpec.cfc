component extends="wheels.Testbox" {

	function beforeAll() {
		params = {controller = "dummy", action = "dummy"}
		_controller = application.wo.controller("dummy", params)
	}

	function run() {

		describe("Tests that flashStorage", () => {

			it("should be enabled in cookies", () => {
				_controller.$setFlashStorage("cookie")

				expect(_controller.$getFlashStorage()).toBe("cookie")
			})

			it("should be enabled in session", () => {
				_controller.$setFlashStorage("session")

				expect(_controller.$getFlashStorage()).toBe("session")
			})
		})

		describe("Tests that flash", () => {

			beforeEach(() => {
				_controller.$setFlashStorage("cookie")
				_controller.flashClear()
				_controller.$setFlashStorage("session")
				_controller.flashClear()
			})

			afterEach(() => {
				_controller.flashClear()
			})

			it("key exists in session", () => {
				_controller.flashInsert(success = "Congrats!")
				result = _controller.flash("success")

				expect(result).toBe("Congrats!")
			})

			it("key exists in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				result = _controller.flash("success")

				expect(result).toBe("Congrats!")
			})

			it("key does not exist in session", () => {
				_controller.flashInsert(success = "Congrats!")
				result = _controller.flash("invalidKey")

				expect(result).toBe("")
			})

			it("key does not exist in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				result = _controller.flash("invalidKey")

				expect(result).toBe("")
			})

			it("key is blank in session", () => {
				_controller.flashInsert(success = "Congrats!")
				result = _controller.flash("")

				expect(result).toBe("")
			})

			it("key is blank in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				result = _controller.flash("")

				expect(result).toBe("")
			})

			it("with provided key is empty in session", () => {
				_controller.flashInsert(success = "Congrats!")
				_controller.flashClear()
				result = _controller.flash("invalidKey")

				expect(result).toBe("")
			})

			it("with provided key is empty in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				_controller.flashClear()
				result = _controller.flash("invalidKey")

				expect(result).toBe("")
			})

			it("with no key provided is not empty in session", () => {
				_controller.flashInsert(success = "Congrats!")
				result = _controller.flash()

				expect(result).toBeStruct()
				expect(result).toHaveKey("success")
			})

			it("with no key provided is not empty in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				result = _controller.flash()

				expect(result).toBeStruct()
				expect(result).toHaveKey("success")
			})

			it("with no key provided is empty in session", () => {
				_controller.flashInsert(success = "Congrats!")
				_controller.flashClear()
				result = _controller.flash()

				expect(result).toBeStruct()
				expect(result).toBeEmpty()
			})

			it("with no key provided is empty in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				_controller.flashClear()
				result = _controller.flash()

				expect(result).toBeStruct()
				expect(result).toBeEmpty()
			})
		})

		describe("Tests that flashClear", () => {

			beforeEach(() => {
				_controller.$setFlashStorage("cookie")
				_controller.flashClear()
				_controller.$setFlashStorage("session")
				_controller.flashClear()
			})

			afterEach(() => {
				_controller.flashClear()
			})

			it("is clearing the flash in session", () => {
				_controller.flashInsert(success = "Congrats!")
				_controller.flashClear()
				result = _controller.flash()

				expect(result).toBeEmpty()
			})

			it("is clearing the flash in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				_controller.flashClear()
				result = _controller.flash()

				expect(result).toBeEmpty()
			})
		})

		describe("Tests that flashCount", () => {

			beforeEach(() => {
				_controller.$setFlashStorage("cookie")
				_controller.flashClear()
				_controller.$setFlashStorage("session")
				_controller.flashClear()
			})

			afterEach(() => {
				_controller.flashClear()
			})

			it("is counting the flash in session", () => {
				_controller.flashInsert(success = "Congrats!")
				_controller.flashInsert(anotherKey = "Test!")
				result = _controller.flashCount()

				expect(result).toBe(2)
			})

			it("is counting the flash in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				_controller.flashInsert(anotherKey = "Test!")
				result = _controller.flashCount()

				expect(result).toBe(2)
			})
		})

		describe("Tests that flashDelete", () => {

			beforeEach(() => {
				_controller.$setFlashStorage("cookie")
				_controller.flashClear()
				_controller.$setFlashStorage("session")
				_controller.flashClear()
			})

			afterEach(() => {
				_controller.flashClear()
			})

			it("is deleting the flash key in session", () => {
				_controller.flashInsert(success = "Congrats!")
				result = _controller.flashDelete(key = "success")

				expect(result).toBeTrue()
			})

			it("is deleting the flash key in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				result = _controller.flashDelete(key = "success")

				expect(result).toBeTrue()
			})
		})

		describe("Tests that flashInsert", () => {

			beforeEach(() => {
				_controller.$setFlashStorage("cookie")
				_controller.flashClear()
				_controller.$setFlashStorage("session")
				_controller.flashClear()
			})

			afterEach(() => {
				_controller.flashClear()
			})

			it("is inserting the flash key in session", () => {
				_controller.flashInsert(success = "Congrats!")

				expect(_controller.flash('success')).toBe("Congrats!")
			})

			it("is inserting the flash key in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")

				expect(_controller.flash('success')).toBe("Congrats!")
			})

			it("is inserting multiple flash keys in session", () => {
				_controller.flashInsert(success = "Congrats!", error = "Error!")

				expect(_controller.flash('success')).toBe("Congrats!")
				expect(_controller.flash('error')).toBe("Error!")
			})

			it("is inserting multiple flash keys in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!", error = "Error!")

				expect(_controller.flash('success')).toBe("Congrats!")
				expect(_controller.flash('error')).toBe("Error!")
			})
		})

		describe("Tests that flashIsEmpty", () => {

			beforeEach(() => {
				_controller.$setFlashStorage("cookie")
				_controller.flashClear()
				_controller.$setFlashStorage("session")
				_controller.flashClear()
			})

			afterEach(() => {
				_controller.flashClear()
			})

			it("is checking that flash is empty in session", () => {
				result = _controller.flashIsEmpty()

				expect(result).toBeTrue()
			})

			it("is checking that flash is empty in cookie", () => {
				_controller.$setFlashStorage("cookie")
				result = _controller.flashIsEmpty()

				expect(result).toBeTrue()
			})

			it("is checking that flash is not empty in session", () => {
				_controller.flashInsert(success = "Congrats!")
				result = _controller.flashIsEmpty()

				expect(result).toBeFalse()
			})

			it("is checking that flash is not empty in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				result = _controller.flashIsEmpty()

				expect(result).toBeFalse()
			})
		})

		describe("Tests that flashKeep", () => {

			beforeEach(() => {
				_controller.$setFlashStorage("cookie")
				_controller.flashClear()
				_controller.$setFlashStorage("session")
				_controller.flashClear()
			})

			afterEach(() => {
				_controller.flashClear()
			})

			it("is keeping the flash after clearing in session", () => {
				_controller.flashInsert(tony = "Petruzzi", per = "Djurner", james = "Gibson")
				_controller.flashKeep("per,james")
				_controller.$flashClear()

				expect(_controller.flashCount()).toBe("2")
				expect(_controller.flashKeyExists("tony")).toBeFalse()
				expect(_controller.flashKeyExists("per")).toBeTrue()
				expect(_controller.flashKeyExists("james")).toBeTrue()
				expect(_controller.flash("per")).toBe("Djurner")
				expect(_controller.flash("james")).toBe("Gibson")
			})

			it("is keeping the flash after clearing in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(tony = "Petruzzi", per = "Djurner", james = "Gibson")
				_controller.flashKeep("per,james")
				_controller.$flashClear()

				expect(_controller.flashCount()).toBe("2")
				expect(_controller.flashKeyExists("tony")).toBeFalse()
				expect(_controller.flashKeyExists("per")).toBeTrue()
				expect(_controller.flashKeyExists("james")).toBeTrue()
				expect(_controller.flash("per")).toBe("Djurner")
				expect(_controller.flash("james")).toBe("Gibson")
			})
		})

		describe("Tests that flashKeyExists", () => {

			beforeEach(() => {
				_controller.$setFlashStorage("cookie")
				_controller.flashClear()
				_controller.$setFlashStorage("session")
				_controller.flashClear()
			})

			afterEach(() => {
				_controller.flashClear()
			})

			it("is checking that key exists in flash in session", () => {
				_controller.flashInsert(success = "Congrats!")
				r = _controller.flashKeyExists("success")

				expect(r).toBeTrue()
			})

			it("is checking that key exists in flash in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				r = _controller.flashKeyExists("success")

				expect(r).toBeTrue()
			})
		})

		describe("Tests that flashMessages", () => {

			beforeEach(() => {
				_controller.$setFlashStorage("cookie")
				_controller.flashClear()
				_controller.$setFlashStorage("session")
				_controller.flashClear()
				application.wo.set(functionName = "flashMessages", encode = false)
			})

			afterEach(() => {
				_controller.flashClear()
				application.wo.set(functionName = "flashMessages", encode = true)
			})

			it("is returning normal output in session", () => {
				_controller.flashInsert(success = "Congrats!")
				_controller.flashInsert(alert = "Error!")
				actual = _controller.flashMessages()

				expect(actual).toBe('<div class="flash-messages"><p class="alert-message">Error!</p><p class="success-message">Congrats!</p></div>')
			})

			it("is returning normal output in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				_controller.flashInsert(alert = "Error!")
				actual = _controller.flashMessages()

				expect(actual).toBe('<div class="flash-messages"><p class="alert-message">Error!</p><p class="success-message">Congrats!</p></div>')
			})

			it("is returning specific key only in session", () => {
				_controller.flashInsert(success = "Congrats!")
				_controller.flashInsert(alert = "Error!")
				actual = _controller.flashMessages(key = "alert")

				expect(actual).toBe('<div class="flash-messages"><p class="alert-message">Error!</p></div>')
			})

			it("is returning specific key only in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				_controller.flashInsert(alert = "Error!")
				actual = _controller.flashMessages(key = "alert")

				expect(actual).toBe('<div class="flash-messages"><p class="alert-message">Error!</p></div>')
			})

			it("is passing through id in session", () => {
				_controller.flashInsert(success = "Congrats!")
				actual = _controller.flashMessages(id = "my-id")

				expect(actual).toInclude('<p class="success-message">Congrats!</p>')
				expect(actual).toInclude('id="my-id"')
			})

			it("is passing through id in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				actual = _controller.flashMessages(id = "my-id")

				expect(actual).toInclude('<p class="success-message">Congrats!</p>')
				expect(actual).toInclude('id="my-id"')
			})

			it("is returning empty flash in session", () => {
				actual = _controller.flashMessages()

				expect(actual).toBe("")
			})

			it("is returning empty flash in cookie", () => {
				_controller.$setFlashStorage("cookie")
				actual = _controller.flashMessages()

				expect(actual).toBe("")
			})

			it("is returning empty flash includeEmptyContainer in session", () => {
				actual = _controller.flashMessages(includeEmptyContainer = "true")

				expect(actual).toBe('<div class="flash-messages"></div>')
			})

			it("is returning empty flash includeEmptyContainer in cookie", () => {
				_controller.$setFlashStorage("cookie")
				actual = _controller.flashMessages(includeEmptyContainer = "true")

				expect(actual).toBe('<div class="flash-messages"></div>')
			})

			it("is appending if allowed in session", () => {
				_controller.$setFlashAppend(true)
				_controller.flashInsert(success = "Congrats!")
				_controller.flashInsert(success = "Congrats Again!")
				actual = _controller.flashMessages()

				expect(actual).toBe('<div class="flash-messages"><p class="success-message">Congrats!</p><p class="success-message">Congrats Again!</p></div>')

				_controller.$setFlashAppend(false)
			})

			it("is appending if allowed in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.$setFlashAppend(true)
				_controller.flashInsert(success = "Congrats!")
				_controller.flashInsert(success = "Congrats Again!")
				actual = _controller.flashMessages()

				expect(actual).toBe('<div class="flash-messages"><p class="success-message">Congrats!</p><p class="success-message">Congrats Again!</p></div>')

				_controller.$setFlashAppend(false)
			})

			it("is allowing complex values in session", () => {
				arr = []
				arr[1] = "Congrats!"
				arr[2] = "Congrats Again!"
				_controller.flashInsert(success = arr)
				actual = _controller.flashMessages()

				expect(actual).toBe('<div class="flash-messages"><p class="success-message">Congrats!</p><p class="success-message">Congrats Again!</p></div>')
			})

			it("is allowing complex values in cookie", () => {
				_controller.$setFlashStorage("cookie")
				arr = []
				arr[1] = "Congrats!"
				arr[2] = "Congrats Again!"
				_controller.flashInsert(success = arr)
				actual = _controller.flashMessages()

				expect(actual).toBe('<div class="flash-messages"><p class="success-message">Congrats!</p><p class="success-message">Congrats Again!</p></div>')
			})

			it("is controlling order via keys in session", () => {
				_controller.flashInsert(success = "Congrats!")
				_controller.flashInsert(alert = "Error!")
				actual = _controller.flashMessages(keys = "success,alert")

				expect(actual).toBe('<div class="flash-messages"><p class="success-message">Congrats!</p><p class="alert-message">Error!</p></div>')

				actual = _controller.flashMessages(keys = "alert,success")

				expect(actual).toBe('<div class="flash-messages"><p class="alert-message">Error!</p><p class="success-message">Congrats!</p></div>')
			})

			it("is controlling order via keys in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "Congrats!")
				_controller.flashInsert(alert = "Error!")
				actual = _controller.flashMessages(keys = "success,alert")

				expect(actual).toBe('<div class="flash-messages"><p class="success-message">Congrats!</p><p class="alert-message">Error!</p></div>')

				actual = _controller.flashMessages(keys = "alert,success")

				expect(actual).toBe('<div class="flash-messages"><p class="alert-message">Error!</p><p class="success-message">Congrats!</p></div>')
			})

			it("is lower-casing the class attribute in session", () => {
				_controller.flashInsert(something = "")
				actual = _controller.flashMessages()
				expected = 'class="something-message"'

				expect(actual).toInclude(expected)
			})

			it("is lower-casing the class attribute in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(something = "")
				actual = _controller.flashMessages()
				expected = 'class="something-message"'

				expect(actual).toInclude(expected)
			})

			it("is lower-casing mixed key in the class attribute in session", () => {
				_controller.flashInsert(someThing = "")
				actual = _controller.flashMessages()
				expected = 'class="something-message"'

				expect(actual).toInclude(expected)
			})

			it("is lower-casing mixed key in the class attribute in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(someThing = "")
				actual = _controller.flashMessages()
				expected = 'class="something-message"'

				expect(actual).toInclude(expected)
			})

			it("is lower-casing uppercase key in the class attribute in session", () => {
				_controller.flashInsert(SOMETHING = "")
				actual = _controller.flashMessages()
				expected = 'class="something-message"'

				expect(actual).toInclude(expected)
			})

			it("is lower-casing uppercase key in the class attribute in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(SOMETHING = "")
				actual = _controller.flashMessages()
				expected = 'class="something-message"'

				expect(actual).toInclude(expected)
			})

			it("is setting class in session", () => {
				_controller.flashInsert(success = "test");
				actual = _controller.flashMessages(class = "custom-class");
				expected = 'class="custom-class"';
				e2 = 'class="success-message"';

				expect(actual).toInclude(expected)
				expect(actual).toInclude(e2)
			})

			it("is setting class in cookie", () => {
				_controller.$setFlashStorage("cookie")
				_controller.flashInsert(success = "test");
				actual = _controller.flashMessages(class = "custom-class");
				expected = 'class="custom-class"';
				e2 = 'class="success-message"';

				expect(actual).toInclude(expected)
				expect(actual).toInclude(e2)
			})
		})

		describe("Tests that flashStorage none", () => {

			it("is not setting key in flash", () => {
				_controller.$setFlashStorage("none")
				_controller.flashInsert(success = "I should not exist", error = "I should not exist either")
				actual = _controller.flashMessages()

				expect(actual).toBe("")
				_controller.flashClear()
			})
		})

		describe("Tests the setFlashStorage", () => {

			beforeEach(() => {
				originalAppStorage = application.wheels.flashStorage;
			})

			afterEach(() => {
				application.wheels.flashStorage = originalAppStorage;
			})

			it("sets flash storage to 'session'", () => {
				_controller.setFlashStorage("session");
				expect(_controller.$getFlashStorage()).toBe("session");
			})

			it("sets flash storage to 'cookie'", () => {
				_controller.setFlashStorage("cookie");
				expect(_controller.$getFlashStorage()).toBe("cookie");
			})

			it("defaults to 'session' when no storage argument is passed", () => {
				_controller.setFlashStorage();
				expect(_controller.$getFlashStorage()).toBe("session");
			})

			it("accepts mixed-case values and normalizes them (e.g. 'COOKIE' to 'cookie')", () => {
				_controller.setFlashStorage("SESSION");
				expect(_controller.$getFlashStorage()).toBe("session");

				_controller.setFlashStorage("CoOkIe");
				expect(_controller.$getFlashStorage()).toBe("cookie");
			})

			it("does not change flash storage if an invalid type is passed", () => {
				_controller.setFlashStorage("cookie");
				_controller.setFlashStorage("invalidType");
				expect(_controller.$getFlashStorage()).toBe("cookie");
			});

			it("updates application-level flashStorage when setGlobally is true", () => {
				_controller.setFlashStorage("cookie", true);
				expect(application.wheels.flashStorage).toBe("cookie");
			})

			it("does not update application-level flashStorage when setGlobally is false", () => {
				application.wheels.flashStorage = "session";
				_controller.setFlashStorage("cookie", false);
				expect(application.wheels.flashStorage).toBe("session");
			})

			it("does not update application-level flashStorage when setGlobally is omitted (defaults to false)", () => {
				application.wheels.flashStorage = "session";
				_controller.setFlashStorage("cookie");
				expect(application.wheels.flashStorage).toBe("session");
			})

			it("sets both controller-level and app-level flashStorage when setGlobally is true", () => {
				_controller.setFlashStorage("cookie", true);
				expect(_controller.$getFlashStorage()).toBe("cookie");
				expect(application.wheels.flashStorage).toBe("cookie");
			})
		})

	}
}
