component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("Authorization policy layer (wheels.Policy + authorize()/can()/policyScope())", () => {

			beforeEach(() => {
				$savedPolicyPath = application.wheels.policyPath
				$savedShowError = application.wheels.showErrorInformation
				application.wheels.policyPath = "/wheels/tests/_assets/policies"

				author = g.model("author").findOne(where = "firstName = 'Per'", order = "id")
				otherAuthor = g.model("author").findOne(where = "firstName = 'Tony'", order = "id")
				post = g.model("post").findOne(where = "authorid = #author.id#", order = "id")

				// Fixture controller whose $currentUserForPolicy() override reads
				// request.$policyTestUser (the documented app customization seam).
				_controller = g.controller("authorization", {controller = "authorization", action = "update"})
			})

			afterEach(() => {
				application.wheels.policyPath = $savedPolicyPath
				application.wheels.showErrorInformation = $savedShowError
				StructDelete(request, "$policyTestUser")
			})

			describe("wheels.Policy base class", () => {

				it("default-denies every standard action", () => {
					basePolicy = CreateObject("component", "wheels.Policy").init(user = {id = 1}, record = post)

					expect(basePolicy.index()).toBeFalse()
					expect(basePolicy.show()).toBeFalse()
					expect(basePolicy.new()).toBeFalse()
					expect(basePolicy.create()).toBeFalse()
					expect(basePolicy.edit()).toBeFalse()
					expect(basePolicy.update()).toBeFalse()
					expect(basePolicy.delete()).toBeFalse()
				})

				it("default-denies scope() with an injection-safe no-rows chain", () => {
					basePolicy = CreateObject("component", "wheels.Policy").init(user = {id = 1}, record = "")
					scoped = basePolicy.scope(g.model("post"))

					expect(g.model("post").count()).toBeGT(0)
					expect(scoped.count()).toBe(0)
					expect(scoped.findAll().recordCount).toBe(0)
				})

				it("default-denies through an app policy that overrides nothing", () => {
					request.$policyTestUser = {id = author.id}

					expect(_controller.can("index", author)).toBeFalse()
					expect(_controller.can("show", author)).toBeFalse()
					expect(_controller.can("update", author)).toBeFalse()
					expect(_controller.policyScope(g.model("author")).count()).toBe(0)
					expect(() => _controller.authorize(record = author, action = "update")).toThrow(
						type = "Wheels.NotAuthorized"
					)
				})
			})

			describe("authorize()", () => {

				it("returns the record when the policy allows", () => {
					request.$policyTestUser = {id = author.id}
					result = _controller.authorize(record = post, action = "update")

					expect(result.id).toBe(post.id)
					expect(result.title).toBe(post.title)
				})

				it("throws Wheels.NotAuthorized when the policy denies", () => {
					request.$policyTestUser = {id = otherAuthor.id}

					expect(() => _controller.authorize(record = post, action = "update")).toThrow(
						type = "Wheels.NotAuthorized"
					)
				})

				it("defaults the action from params.action at call time", () => {
					// _controller was created with params.action = "update".
					request.$policyTestUser = {id = author.id}
					result = _controller.authorize(post)
					expect(result.id).toBe(post.id)

					request.$policyTestUser = {id = otherAuthor.id}
					expect(() => _controller.authorize(post)).toThrow(type = "Wheels.NotAuthorized")
				})

				it("throws Wheels.Policy.MissingAction when no action can be resolved in development/testing", () => {
					actionless = g.controller("authorization", {controller = "authorization"})
					request.$policyTestUser = {id = author.id}

					expect(() => actionless.authorize(post)).toThrow(type = "Wheels.Policy.MissingAction")
				})

				it("denies a guest (no user)", () => {
					// No request.$policyTestUser -> the resolver returns "" (guest).
					expect(() => _controller.authorize(record = post, action = "update")).toThrow(
						type = "Wheels.NotAuthorized"
					)
				})

				it("denies a custom action the policy has no method for", () => {
					request.$policyTestUser = {id = author.id}

					expect(() => _controller.authorize(record = post, action = "publish")).toThrow(
						type = "Wheels.NotAuthorized"
					)
				})

				it("denies the boolean false a missed finder returns", () => {
					request.$policyTestUser = {id = author.id}

					expect(() => _controller.authorize(record = false, action = "update")).toThrow(
						type = "Wheels.NotAuthorized"
					)
				})
			})

			describe("can()", () => {

				it("returns true when the policy grants the action", () => {
					request.$policyTestUser = {id = author.id}

					expect(_controller.can("update", post)).toBeTrue()
					expect(_controller.can("index", post)).toBeTrue()
					expect(_controller.can("show", post)).toBeTrue()
				})

				it("returns false when the policy denies the action", () => {
					request.$policyTestUser = {id = otherAuthor.id}

					expect(_controller.can("update", post)).toBeFalse()
					// Inherited default-deny from the base class.
					expect(_controller.can("delete", post)).toBeFalse()
				})

				it("returns false for a guest on user-gated actions but true on public ones", () => {
					expect(_controller.can("index", post)).toBeFalse()
					expect(_controller.can("update", post)).toBeFalse()
					expect(_controller.can("show", post)).toBeTrue()
				})

				it("returns false for a custom action the policy has no method for", () => {
					request.$policyTestUser = {id = author.id}

					expect(_controller.can("publish", post)).toBeFalse()
				})

				it("returns false for an empty record", () => {
					request.$policyTestUser = {id = author.id}

					expect(_controller.can("update")).toBeFalse()
				})
			})

			describe("policyScope()", () => {

				it("narrows the collection to the policy's scope", () => {
					request.$policyTestUser = {id = author.id}
					expected = g.model("post").count(where = "authorid = #author.id#")
					scoped = _controller.policyScope(g.model("post"))

					expect(expected).toBeGT(0)
					expect(g.model("post").count()).toBeGT(expected)
					expect(scoped.count()).toBe(expected)
				})

				it("returns a chain that keeps composing", () => {
					request.$policyTestUser = {id = author.id}
					expected = g.model("post").count(where = "authorid = #author.id# AND status = 'published'")
					scoped = _controller.policyScope(g.model("post")).where("status", "published")

					expect(expected).toBeGT(0)
					expect(scoped.count()).toBe(expected)
				})

				it("default-denies (no rows) for a guest via the inherited base scope", () => {
					expect(g.model("post").count()).toBeGT(0)
					expect(_controller.policyScope(g.model("post")).count()).toBe(0)
				})

				it("throws Wheels.Policy.InvalidCollection for an in-flight chain in development/testing", () => {
					request.$policyTestUser = {id = author.id}
					builder = g.model("post").where("views", ">", 0)

					expect(() => _controller.policyScope(builder)).toThrow(type = "Wheels.Policy.InvalidCollection")
				})
			})

			describe("missing policy class", () => {

				it("throws Wheels.Policy.NotDefined in development/testing", () => {
					request.$policyTestUser = {id = author.id}
					comment = g.model("comment").findOne(order = "id")

					expect(() => _controller.can("update", comment)).toThrow(type = "Wheels.Policy.NotDefined")
					expect(() => _controller.authorize(record = comment, action = "update")).toThrow(
						type = "Wheels.Policy.NotDefined"
					)
					expect(() => _controller.policyScope(g.model("comment"))).toThrow(
						type = "Wheels.Policy.NotDefined"
					)
				})

				it("silently denies in production (showErrorInformation off)", () => {
					request.$policyTestUser = {id = author.id}
					comment = g.model("comment").findOne(order = "id")
					application.wheels.showErrorInformation = false

					expect(_controller.can("update", comment)).toBeFalse()
					expect(g.model("comment").count()).toBeGT(0)
					expect(_controller.policyScope(g.model("comment")).count()).toBe(0)
				})
			})

			describe("identity resolution", () => {

				it("resolves a guest (empty string) through the default seam when nothing is registered", () => {
					plain = g.controller("test", {controller = "test", action = "show"})

					expect(plain.$currentUserForPolicy()).toBe("")
					expect(plain.can("update", post)).toBeFalse()
					expect(plain.can("show", post)).toBeTrue()
				})
			})

			describe("routable surface", () => {

				it("registers authorize/can/policyScope as protected controller methods", () => {
					expect(ListFindNoCase(application.wheels.protectedControllerMethods, "authorize")).toBeGT(0)
					expect(ListFindNoCase(application.wheels.protectedControllerMethods, "can")).toBeGT(0)
					expect(ListFindNoCase(application.wheels.protectedControllerMethods, "policyScope")).toBeGT(0)
				})
			})
		})
	}
}
