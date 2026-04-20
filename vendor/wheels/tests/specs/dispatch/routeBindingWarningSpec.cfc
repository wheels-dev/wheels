component extends="wheels.WheelsTest" {

	function run() {

		describe("Route Model Binding dev-mode warning", () => {

			beforeEach(() => {
				dispatch = CreateObject("component", "wheels.Dispatch")

				// Clear the per-process dedup cache between tests so each spec starts fresh.
				if (StructKeyExists(application, "$wheelsRouteBindingWarnings")) {
					StructClear(application.$wheelsRouteBindingWarnings)
				}

				_originalEnv = application.wheels.environment
				_originalSuppress = StructKeyExists(application.wheels, "suppressRouteBindingWarnings")
					? application.wheels.suppressRouteBindingWarnings
					: false

				// Ensure warnings are enabled in a known state for the tests.
				application.wheels.environment = "development"
				application.wheels.suppressRouteBindingWarnings = false
			})

			afterEach(() => {
				application.wheels.environment = _originalEnv
				application.wheels.suppressRouteBindingWarnings = _originalSuppress
				if (StructKeyExists(application, "$wheelsRouteBindingWarnings")) {
					StructClear(application.$wheelsRouteBindingWarnings)
				}
			})

			it("warns when binding is off, key is set, and action is a member action", () => {
				params = {controller = "posts", action = "show", key = "42"}
				route = {name = "post", controller = "posts", action = "show"}
				result = dispatch.$maybeWarnRouteBinding(params = params, route = route)
				expect(result).toBeTrue()
			})

			it("does not warn when key is absent (e.g., index action)", () => {
				params = {controller = "posts", action = "index"}
				route = {name = "posts", controller = "posts", action = "index"}
				result = dispatch.$maybeWarnRouteBinding(params = params, route = route)
				expect(result).toBeFalse()
			})

			it("does not warn for non-member actions (new, create, index)", () => {
				params = {controller = "posts", action = "new", key = "42"}
				route = {name = "newPost", controller = "posts", action = "new"}
				result = dispatch.$maybeWarnRouteBinding(params = params, route = route)
				expect(result).toBeFalse()
			})

			it("warns for each of show, edit, update, delete", () => {
				for (action in ["show", "edit", "update", "delete"]) {
					// Fresh dedup cache per action.
					if (StructKeyExists(application, "$wheelsRouteBindingWarnings")) {
						StructClear(application.$wheelsRouteBindingWarnings)
					}
					params = {controller = "posts", action = action, key = "42"}
					route = {name = "post", controller = "posts", action = action}
					result = dispatch.$maybeWarnRouteBinding(params = params, route = route)
					expect(result).toBeTrue()
				}
			})

			it("warns only once per controller+action (dedup within lifetime)", () => {
				params = {controller = "posts", action = "show", key = "42"}
				route = {name = "post", controller = "posts", action = "show"}
				first = dispatch.$maybeWarnRouteBinding(params = params, route = route)
				second = dispatch.$maybeWarnRouteBinding(params = params, route = route)
				third = dispatch.$maybeWarnRouteBinding(params = params, route = route)

				expect(first).toBeTrue()
				expect(second).toBeFalse()
				expect(third).toBeFalse()
			})

			it("deduplicates per controller+action pair independently", () => {
				p1 = {controller = "posts", action = "show", key = "1"}
				p2 = {controller = "posts", action = "edit", key = "1"}
				p3 = {controller = "comments", action = "show", key = "1"}
				route = {name = "r", controller = "posts", action = "show"}

				// Different action on same controller still fires.
				expect(dispatch.$maybeWarnRouteBinding(params = p1, route = route)).toBeTrue()
				expect(dispatch.$maybeWarnRouteBinding(params = p2, route = route)).toBeTrue()
				// Different controller still fires.
				expect(dispatch.$maybeWarnRouteBinding(params = p3, route = route)).toBeTrue()
				// All three repeat => silence.
				expect(dispatch.$maybeWarnRouteBinding(params = p1, route = route)).toBeFalse()
				expect(dispatch.$maybeWarnRouteBinding(params = p2, route = route)).toBeFalse()
				expect(dispatch.$maybeWarnRouteBinding(params = p3, route = route)).toBeFalse()
			})

			it("does not warn in production environment", () => {
				application.wheels.environment = "production"
				params = {controller = "posts", action = "show", key = "42"}
				route = {name = "post", controller = "posts", action = "show"}
				result = dispatch.$maybeWarnRouteBinding(params = params, route = route)
				expect(result).toBeFalse()
			})

			it("does not warn when suppressRouteBindingWarnings is true", () => {
				application.wheels.suppressRouteBindingWarnings = true
				params = {controller = "posts", action = "show", key = "42"}
				route = {name = "post", controller = "posts", action = "show"}
				result = dispatch.$maybeWarnRouteBinding(params = params, route = route)
				expect(result).toBeFalse()
			})

			it("does not warn when controller cannot be determined", () => {
				params = {action = "show", key = "42"}
				route = {name = "post", action = "show"}
				result = dispatch.$maybeWarnRouteBinding(params = params, route = route)
				expect(result).toBeFalse()
			})

			it("does not warn when binding is enabled on the route (integration via $resolveRouteModelBinding)", () => {
				// When binding is true, $resolveRouteModelBinding does not invoke the helper.
				// Verify: dedup cache stays empty even after a call that would otherwise warn.
				params = {controller = "nonexistentmodeltestxyz", action = "show", key = "42"}
				route = {controller = "nonexistentmodeltestxyz", action = "show", binding = true}
				// Model won't resolve (no such model) so $resolveRouteModelBinding returns early
				// after the "model doesn't exist" catch — but it never calls the warning path.
				try {
					dispatch.$resolveRouteModelBinding(params = params, route = route)
				} catch (any e) { /* model resolution may throw; we only care about the warning side effect */ }
				hasDedup = StructKeyExists(application, "$wheelsRouteBindingWarnings")
					&& StructKeyExists(application.$wheelsRouteBindingWarnings, "nonexistentmodeltestxyz##show")
				expect(hasDedup).toBeFalse()
			})

			it("fires via $resolveRouteModelBinding when binding is off and route is a candidate", () => {
				params = {controller = "widgetsnonexistent", action = "show", key = "42"}
				route = {controller = "widgetsnonexistent", action = "show"}
				// binding not set on route, global routeModelBinding defaults false
				dispatch.$resolveRouteModelBinding(params = params, route = route)
				hasDedup = StructKeyExists(application, "$wheelsRouteBindingWarnings")
					&& StructKeyExists(application.$wheelsRouteBindingWarnings, "widgetsnonexistent##show")
				expect(hasDedup).toBeTrue()
			})
		})
	}
}
