/**
 * Authorization policy layer. Desk IDs S1–S9 stay locked.
 * PROVEN: S1 unknown action throws Wheels.Policy.UnknownAction, S2 empty-id
 * fail-closed, S3 throwing identity seams fail loud, S4 only boolean true
 * grants, S5 production InvalidCollection, S6 DI/authenticator identity,
 * S7 guest "", S8 production 403, S9 reserved action=scope/init.
 *
 * Directory-scoped so `wheels test --core --ci --filter=Authorization` discovers
 * this folder (a single-file directory= scope finds 0 bundles).
 */
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
				StructDelete(request, "$wheelsIsolateAbort")
				try {
					g.$header(statusCode = 200)
				} catch (any e) {
				}
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

				it("S2: empty resolved ids never become a matching-all or invalid-SQL whereIn", () => {
					spy = CreateObject("component", "wheels.tests._assets.policies.WhereInSpy")
					basePolicy = CreateObject("component", "wheels.Policy").init(user = {id = 1}, record = "")
					scoped = basePolicy.scope(spy)

					expect(g.model("post").count()).toBeGT(0)
					expect(spy.whereInCalls).toBe(0)
					expect(scoped.count()).toBe(0)
					expect(scoped.findAll().recordCount).toBe(0)
				})

				it("S7: Policy.cfc missing user is the guest empty string", () => {
					guestPolicy = CreateObject("component", "wheels.Policy").init()

					expect(guestPolicy.currentUser()).toBe("")
					expect(IsSimpleValue(guestPolicy.currentUser())).toBeTrue()
					expect(IsObject(guestPolicy.currentUser())).toBeFalse()
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

				it("S1: authorize() throws Wheels.Policy.UnknownAction for a missing policy method", () => {
					request.$policyTestUser = {id = author.id}

					expect(() => _controller.authorize(record = post, action = "publish")).toThrow(
						type = "Wheels.Policy.UnknownAction"
					)
				})

				it("S4: authorize() denies the CFML string yes", () => {
					request.$policyTestUser = {id = author.id}

					expect(() => _controller.authorize(record = post, action = "yesGrant")).toThrow(
						type = "Wheels.NotAuthorized"
					)
				})

				it("S4: authorize() denies the CFML string true", () => {
					request.$policyTestUser = {id = author.id}

					expect(() => _controller.authorize(record = post, action = "trueGrant")).toThrow(
						type = "Wheels.NotAuthorized"
					)
				})

				it("S4: authorize() returns the record when the policy returns boolean true", () => {
					request.$policyTestUser = {id = author.id}
					result = _controller.authorize(record = post, action = "boolGrant")

					expect(result.id).toBe(post.id)
				})

				it("denies the boolean false a missed finder returns", () => {
					request.$policyTestUser = {id = author.id}

					expect(() => _controller.authorize(record = false, action = "update")).toThrow(
						type = "Wheels.NotAuthorized"
					)
				})

				it("S8: authorize() denial in production is HTTP 403, not a silent allow", () => {
					application.wheels.showErrorInformation = false
					request.$wheelsIsolateAbort = true
					request.$policyTestUser = {id = otherAuthor.id}
					denied = {allowed = false, status = 0, type = ""}
					try {
						_controller.authorize(record = post, action = "update")
						denied.allowed = true
					} catch (any e) {
						denied.type = e.type
					}
					denied.status = Val(g.$statusCode())
					src = FileRead(ExpandPath("/wheels/controller/authorization.cfc"))

					expect(denied.allowed).toBeFalse()
					expect(denied.status).toBe(403)
					expect(denied.type).toBe("Wheels.NotAuthorized")
					expect(FindNoCase("abort;", src)).toBeGT(0)
					try {
						g.$header(statusCode = 200)
					} catch (any e) {
					}
					StructDelete(request, "$wheelsIsolateAbort")
				})

				it("S9: authorize() with action=scope throws Wheels.NotAuthorized and does not Invoke scope", () => {
					request.$policyTestUser = {id = author.id}

					expect(() => _controller.authorize(record = post, action = "scope")).toThrow(
						type = "Wheels.NotAuthorized"
					)
				})

				it("S9: authorize() with action=init throws Wheels.NotAuthorized and does not Invoke init", () => {
					request.$policyTestUser = {id = author.id}

					expect(() => _controller.authorize(record = post, action = "init")).toThrow(
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

				it("S1: can() throws Wheels.Policy.UnknownAction for a missing policy method", () => {
					request.$policyTestUser = {id = author.id}

					expect(() => _controller.can("publish", post)).toThrow(type = "Wheels.Policy.UnknownAction")
				})

				it("S4: can() denies the CFML strings yes and true and grants boolean true", () => {
					request.$policyTestUser = {id = author.id}

					expect(_controller.can("yesGrant", post)).toBeFalse()
					expect(_controller.can("trueGrant", post)).toBeFalse()
					expect(_controller.can("boolGrant", post)).toBeTrue()
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

				it("S5: production InvalidCollection fail-closes without calling whereIn", () => {
					application.wheels.showErrorInformation = false
					spy = CreateObject("component", "wheels.tests._assets.policies.WhereInSpy")
					scoped = _controller.policyScope(spy)

					expect(spy.whereInCalls).toBe(0)
					expect(scoped.count()).toBe(0)
				})

				it("S5: production InvalidCollection does not fall through to whereIn on a collection without whereIn", () => {
					application.wheels.showErrorInformation = false
					bad = {notAModel = true}
					state = {threw = false, count = -1}
					try {
						scoped = _controller.policyScope(bad)
						state.count = scoped.count()
					} catch (any e) {
						state.threw = true
					}

					expect(state.threw).toBeFalse()
					expect(state.count).toBe(0)
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

				it("S6: policy identity comes from the DI currentUser service", () => {
					savedDi = application.wheelsdi
					di = new wheels.Injector(binderPath = "wheels.tests._assets.di.TestBindings")
					di.map("currentUser").to("wheels.tests._assets.policies.CurrentUserStub")
					application.wheelsdi = di
					identity = {id = "", name = ""}
					try {
						plain = g.controller("test", {controller = "test", action = "show"})
						resolved = plain.$currentUserForPolicy()
						identity.id = resolved.id
						identity.name = resolved.name
					} finally {
						application.wheelsdi = savedDi
					}

					expect(identity.id).toBe(9001)
					expect(identity.name).toBe("policy-di-user")
				})

				it("S3: a throwing DI currentUser does not fail over to the authenticator user", () => {
					savedDi = application.wheelsdi
					di = new wheels.Injector(binderPath = "wheels.tests._assets.di.TestBindings")
					di.map("currentUser").to("wheels.tests._assets.policies.CurrentUserThrowingStub")
					di.map("authenticator").to("wheels.auth.Authenticator").asSingleton()
					application.wheelsdi = di
					state = {threw = false, type = "", userId = ""}
					try {
						auth = di.getInstance("authenticator")
						strategy = new wheels.auth.SessionStrategy()
						strategy.login(principal = {id = 4242, name = "policy-auth-user"})
						auth.registerStrategy(name = "session", strategy = strategy)
						plain = g.controller("test", {controller = "test", action = "show"})
						try {
							resolved = plain.$currentUserForPolicy()
							if (IsStruct(resolved) && StructKeyExists(resolved, "id")) {
								state.userId = resolved.id
							}
						} catch (any e) {
							state.threw = true
							state.type = e.type
						}
					} finally {
						application.wheelsdi = savedDi
						StructDelete(session, "wheels")
					}

					expect(state.threw).toBeTrue()
					expect(state.userId).toBe("")
					expect(state.type).toBe("Wheels.Policy.CurrentUserBoom")
				})

				it("S3: a throwing authenticator currentUser does not become guest empty string", () => {
					savedDi = application.wheelsdi
					di = new wheels.Injector(binderPath = "wheels.tests._assets.di.TestBindings")
					di.map("authenticator").to("wheels.auth.Authenticator").asSingleton()
					application.wheelsdi = di
					state = {threw = false, type = "", guest = false}
					try {
						auth = di.getInstance("authenticator")
						throwingStrategy = CreateObject("component", "wheels.tests._assets.policies.ThrowingCurrentUserStrategy")
						auth.registerStrategy(name = "throwing", strategy = throwingStrategy)
						plain = g.controller("test", {controller = "test", action = "show"})
						try {
							resolved = plain.$currentUserForPolicy()
							state.guest = (IsSimpleValue(resolved) && resolved == "")
						} catch (any e) {
							state.threw = true
							state.type = e.type
						}
					} finally {
						application.wheelsdi = savedDi
					}

					expect(state.threw).toBeTrue()
					expect(state.guest).toBeFalse()
					expect(state.type).toBe("Wheels.Policy.AuthenticatorBoom")
				})

				it("S6: policy identity comes from the authenticator strategy currentUser()", () => {
					savedDi = application.wheelsdi
					di = new wheels.Injector(binderPath = "wheels.tests._assets.di.TestBindings")
					di.map("authenticator").to("wheels.auth.Authenticator").asSingleton()
					application.wheelsdi = di
					identity = {id = "", name = ""}
					try {
						auth = di.getInstance("authenticator")
						strategy = new wheels.auth.SessionStrategy()
						strategy.login(principal = {id = 4242, name = "policy-auth-user"})
						auth.registerStrategy(name = "session", strategy = strategy)
						plain = g.controller("test", {controller = "test", action = "show"})
						resolved = plain.$currentUserForPolicy()
						identity.id = resolved.id
						identity.name = resolved.name
					} finally {
						application.wheelsdi = savedDi
						StructDelete(session, "wheels")
					}

					expect(identity.id).toBe(4242)
					expect(identity.name).toBe("policy-auth-user")
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
