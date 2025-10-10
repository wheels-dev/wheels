component extends="wheels.Testbox" {

	function beforeAll(){
		miscellaneous = application.wirebox.getInstance( "wheels.Controller" );
	};

	function run() {

		g = application.wo

		describe("Tests that $element", () => {

			it("works with all options", () => {
				_controller = g.controller(name = "dummy")
				args = {}
				args.name = "textarea"
				args.attributes = {}
				args.attributes.rows = 10
				args.attributes.cols = 40
				args.attributes.name = "textareatest"
				args.content = "this is a test to see if textarea renders"

				e = _controller.$element(argumentcollection = args)
				r = '<textare cols="40" name="textareatest" rows="10">this is a test to see if textare renders</textarea>'

				expect(r).toBe(r)
			})
		})

		describe("Tests that $getObject", () => {

			

			it("is getting object from request scope", () => {
				request.obj = g.model("post").findOne()
				result = miscellaneous.$getObject( objectname = "request.obj", variableScope = variables )

				expect(result).toBeInstanceOf("post")
			})

			it("is getting object from default scope", () => {
				obj = g.model("post").findOne()
				result = miscellaneous.$getObject( objectname = "obj", variableScope = variables )

				expect(result).toBeInstanceOf("post")
			})

			it("is getting object from variables scope", () => {
				variables.obj = g.model("post").findOne()
				result = miscellaneous.$getObject( objectname = "variables.obj", variableScope = variables )

				expect(result).toBeInstanceOf("post")
			})
		})

		describe("Tests that $tagID and $tagName", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
			})

			it("works with struct", () => {
				args.objectname = {firstname = "tony", lastname = "petruzzi"}
				args.property = "lastname"

				e = _controller.$tagid(argumentcollection = args)
				r = "lastname"

				expect(e).toBe(r)

				e = _controller.$tagname(argumentcollection = args)

				expect(e).toBe(r)
			})

			it("works with string", () => {
				args.objectname = "wheels.Test.view.miscellaneous"
				args.property = "lastname"

				e = _controller.$tagid(argumentcollection = args)
				r = "miscellaneous-lastname"

				expect(e).toBe(r)

				e = _controller.$tagname(argumentcollection = args)
				r = "miscellaneous[lastname]"
				
				expect(e).toBe(r)
			})

			it("works with array", () => {
				args.objectname = [1, 2, 3, 4]
				args.property = "lastname"

				e = _controller.$tagid(argumentcollection = args)
				r = "lastname"

				expect(e).toBe(r)

				e = _controller.$tagname(argumentcollection = args)
				
				expect(e).toBe(r)
			})
		})

		describe("Tests that contentFor", () => {

			beforeEach(() => {
				_params = {controller = "dummy", action = "dummy"}
				_controller = g.controller("dummy", _params)
			})

			it("is specifying positions overwrite false", () => {
				_controller.contentFor(testing = "A")
				_controller.contentFor(testing = "B")
				_controller.contentFor(testing = "C", position = "first")
				_controller.contentFor(testing = "D", position = "2")
				r = _controller.includeContent("testing")
				e = "C#Chr(10)#D#Chr(10)#A#Chr(10)#B"

				expect(e).toBe(r)
			})

			it("is specifying positions overwrite true", () => {
				_controller.contentFor(testing = "A")
				_controller.contentFor(testing = "B")
				_controller.contentFor(testing = "C", position = "first", overwrite = "true")
				_controller.contentFor(testing = "D", position = "2", overwrite = "true")
				r = _controller.includeContent("testing")
				e = "C#Chr(10)#D"
				
				expect(e).toBe(r)
			})

			it("overwrites all", () => {
				_controller.contentFor(testing = "A")
				_controller.contentFor(testing = "B")
				_controller.contentFor(testing = "C", overwrite = "all")
				r = _controller.includeContent("testing")

				expect(r).toBe("C")
			})

			it("should not give error when specifying position out of size", () => {
				_controller.contentFor(testing = "A")
				_controller.contentFor(testing = "B")
				_controller.contentFor(testing = "C")
				_controller.contentFor(testing = "D", position = "6")
				r = _controller.includeContent("testing")
				e = ["A", "B", "C", "D"]
				e = ArrayToList(e, Chr(10))

				expect(e).toBe(r)

				_controller.contentFor(testing = "D", position = "-5")
				r = _controller.includeContent("testing")
				e = ["D", "A", "B", "C", "D"]
				e = ArrayToList(e, Chr(10))

				expect(e).toBe(r)
			})
		})

		describe("Tests that cycle", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				args = {}
				args.values = "1,2,3,4,5,6"
				args.name = "cycle_test"
				container = ListToArray(args.values)
			})

			it("works named", () => {
				for (r in container) {
					e = _controller.cycle(argumentcollection = args)

					expect(e).toBe(r)
				}
			})

			it("works not named", () => {
				StructDelete(args, "name")
				for (r in container) {
					e = _controller.cycle(argumentcollection = args)

					expect(e).toBe(r)
				}
			})
		})

		describe("Tests that resetcycle", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				args = {}
				args.values = "1,2,3,4,5,6"
				args.name = "cycle_test_2"
				container = ListToArray(args.values)
			})

			it("works named", () => {
				for (r in container) {
					_controller.cycle(argumentcollection = args)
				}

				expect(request.wheels.cycle[args.name]).toBe(6)

				_controller.resetcycle(args.name)

				expect(request.wheels.cycle).notToHaveKey(args.name)
			})

			it("works not named", () => {
				StructDelete(args, "name")
				for (r in container) {
					_controller.cycle(argumentcollection = args)
				}

				expect(request.wheels.cycle["default"]).toBe(6)

				_controller.resetcycle()

				expect(request.wheels.cycle).notToHaveKey("default")
			})
		})

		describe("Tests that tag", () => {

			beforeEach(() => {
				_controller = g.controller(name = "dummy")
				args = {}
				args.name = "input"
				args.attributes = {}
				args.attributes.type = "text"
				args.attributes.class = "wheelstest"
				args.attributes.size = "30"
				args.attributes.maxlength = "50"
				args.attributes.name = "inputtest"
				args.attributes.firstname = "tony"
				args.attributes.lastname = "petruzzi"
				args.attributes._firstname = "tony"
				args.attributes._lastname = "petruzzi"
				args.attributes.id = "inputtest"
				args.skip = "firstname,lastname"
				args.skipStartingWith = "_"
				args.attributes.onmouseover = "function(this){this.focus();}"
			})

			it("works with all options", () => {
				e = _controller.$tag(argumentCollection = args)
				r = '<input class="wheelstest" id="inputtest" maxlength="50" name="inputtest" onmouseover="function(this){this.focus();}" size="30" type="text">'

				expect(e).toBe(r)
			})

			it("is passing through class", () => {
				request.wheels.testPaginationLinksQuery = {currentPage = 2, totalPages = 3}
				r = g.controller("dummy").paginationLinks(classForCurrent = "active", handle = "testPaginationLinksQuery")

				expect(r).toInclude("<span class=""active"">2</span>")
			})

			it("addClass attributes adds value in class", () => {
				args.addClass = "newClass"
				e = _controller.$tag(argumentCollection = args)
				r = '<input class="wheelstest newClass" id="inputtest" maxlength="50" name="inputtest" onmouseover="function(this){this.focus();}" size="30" type="text">'

				expect(e).toBe(r)
			})
		})
	}
}