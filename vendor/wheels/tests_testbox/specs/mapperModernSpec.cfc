component extends="wheels.Testbox" {

	function beforeAll() {
		config = {path = "wheels", fileName = "Mapper", method = "$init"}
		_params = {controller = "test", action = "index"}
		_originalRoutes = Duplicate(application.wheels.routes)
		_originalRouteIndex = StructKeyExists(application.wheels, "routeIndex") ? Duplicate(application.wheels.routeIndex) : {}
		_originalStaticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? Duplicate(application.wheels.staticRoutes) : {}
	}

	function afterAll() {
		application.wheels.routes = _originalRoutes
		if (!StructIsEmpty(_originalRouteIndex)) {
			application.wheels.routeIndex = _originalRouteIndex
		}
		if (!StructIsEmpty(_originalStaticRoutes)) {
			application.wheels.staticRoutes = _originalStaticRoutes
		}
	}

	function run() {

		// -----------------------------------------------------------------------
		// group() tests
		// -----------------------------------------------------------------------
		describe("Tests that group()", () => {

			beforeEach(() => {
				$clearRoutes()
			})

			it("groups routes with a path prefix", () => {
				$mapper()
					.$draw()
					.group(path="admin", callback=function(map) {
						map.get(name="dashboard", to="admin##dashboard")
					})
					.end()

				expect(application.wheels.routes).toHaveLength(1)
				expect(application.wheels.routes[1].pattern).toBe("/admin/dashboard")
			})

			it("groups routes with a name prefix", () => {
				$mapper()
					.$draw()
					.group(name="admin", path="admin", callback=function(map) {
						map.get(name="dashboard", to="admin##dashboard")
					})
					.end()

				expect(application.wheels.routes[1]).toHaveKey("name")
				expect(application.wheels.routes[1].name).toBe("adminDashboard")
			})

			it("groups routes with shared constraints", () => {
				$mapper()
					.$draw()
					.group(path="users", constraints={key: "\d+"}, callback=function(map) {
						map.get(name="showUser", pattern="[key]", to="users##show")
					})
					.end()

				expect(application.wheels.routes[1].pattern).toBe("/users/[key]")
				// The constraint should restrict key to digits
				expect(application.wheels.routes[1].constraints).toHaveKey("key")
				expect(application.wheels.routes[1].constraints.key).toBe("\d+")
			})

			it("does not add package to controller (unlike namespace)", () => {
				$mapper()
					.$draw()
					.group(path="admin", callback=function(map) {
						map.get(name="users", to="users##index")
					})
					.end()

				// group() should NOT prefix the controller with a package
				expect(application.wheels.routes[1].controller).toBe("users")
			})

			it("supports nesting groups", () => {
				$mapper()
					.$draw()
					.group(path="api", callback=function(map) {
						map.group(path="v1", callback=function(v1) {
							v1.get(name="users", to="users##index")
						})
					})
					.end()

				expect(application.wheels.routes[1].pattern).toBe("/api/v1/users")
			})

			it("works with manual end() when no callback", () => {
				$mapper()
					.$draw()
					.group(path="admin")
					.get(name="dashboard", to="admin##dashboard")
					.end()
					.end()

				expect(application.wheels.routes[1].pattern).toBe("/admin/dashboard")
			})
		})

		// -----------------------------------------------------------------------
		// api() and version() tests
		// -----------------------------------------------------------------------
		describe("Tests that api() and version()", () => {

			beforeEach(() => {
				$clearRoutes()
			})

			it("creates API-scoped routes with default path", () => {
				$mapper()
					.$draw()
					.api(callback=function(api) {
						api.get(name="users", to="users##index")
					})
					.end()

				expect(application.wheels.routes[1].pattern).toBe("/api/users")
			})

			it("creates API-scoped routes with custom path", () => {
				$mapper()
					.$draw()
					.api(path="services", callback=function(api) {
						api.get(name="status", to="services##status")
					})
					.end()

				expect(application.wheels.routes[1].pattern).toBe("/services/status")
			})

			it("creates versioned API routes", () => {
				$mapper()
					.$draw()
					.api(callback=function(api) {
						api.version(number=1, callback=function(v1) {
							v1.get(name="users", to="users##index")
						})
						api.version(number=2, callback=function(v2) {
							v2.get(name="users", to="users##index")
						})
					})
					.end()

				expect(application.wheels.routes).toHaveLength(2)
				expect(application.wheels.routes[1].pattern).toBe("/api/v1/users")
				expect(application.wheels.routes[2].pattern).toBe("/api/v2/users")
			})

			it("generates correct named routes for versioned APIs", () => {
				$mapper()
					.$draw()
					.api(callback=function(api) {
						api.version(number=1, callback=function(v1) {
							v1.get(name="users", to="users##index")
						})
					})
					.end()

				expect(application.wheels.routes[1]).toHaveKey("name")
				expect(application.wheels.routes[1].name).toBe("apiV1Users")
			})

			it("version() works with resources", () => {
				$mapper()
					.$draw()
					.api(callback=function(api) {
						api.version(number=1, callback=function(v1) {
							v1.resources(name="posts", mapFormat=false)
						})
					})
					.end()

				// resources generates 8 routes without format mapping
				expect(application.wheels.routes).toHaveLength(8)
				// Check that paths are prefixed correctly
				local.patterns = []
				for (local.route in application.wheels.routes) {
					ArrayAppend(local.patterns, local.route.pattern)
				}
				// The index route should be /api/v1/posts
				expect(local.patterns).toInclude("/api/v1/posts")
			})
		})

		// -----------------------------------------------------------------------
		// Typed constraint helper tests
		// -----------------------------------------------------------------------
		describe("Tests that typed constraint helpers", () => {

			beforeEach(() => {
				$clearRoutes()
			})

			it("whereNumber constrains to digits", () => {
				$mapper()
					.$draw()
					.get(name="user", pattern="users/[id]", to="users##show")
						.whereNumber("id")
					.end()

				expect(application.wheels.routes[1].constraints.id).toBe("\d+")
				// Should match digits
				expect("users/123").toMatch(application.wheels.routes[1].regex)
				// Should NOT match alphabetic
				expect("users/abc").notToMatch(application.wheels.routes[1].regex)
			})

			it("whereAlpha constrains to letters", () => {
				$mapper()
					.$draw()
					.get(name="category", pattern="categories/[slug]", to="categories##show")
						.whereAlpha("slug")
					.end()

				expect(application.wheels.routes[1].constraints.slug).toBe("[a-zA-Z]+")
				expect("categories/electronics").toMatch(application.wheels.routes[1].regex)
				expect("categories/123").notToMatch(application.wheels.routes[1].regex)
			})

			it("whereAlphaNumeric constrains to alphanumeric", () => {
				$mapper()
					.$draw()
					.get(name="product", pattern="products/[code]", to="products##show")
						.whereAlphaNumeric("code")
					.end()

				expect(application.wheels.routes[1].constraints.code).toBe("[a-zA-Z0-9]+")
				expect("products/abc123").toMatch(application.wheels.routes[1].regex)
			})

			it("whereUuid constrains to UUID format", () => {
				$mapper()
					.$draw()
					.get(name="item", pattern="items/[guid]", to="items##show")
						.whereUuid("guid")
					.end()

				expect(application.wheels.routes[1].constraints.guid).toInclude("[0-9a-fA-F]")
				expect("items/550e8400-e29b-41d4-a716-446655440000").toMatch(application.wheels.routes[1].regex)
				expect("items/not-a-uuid").notToMatch(application.wheels.routes[1].regex)
			})

			it("whereSlug constrains to URL-friendly slugs", () => {
				$mapper()
					.$draw()
					.get(name="post", pattern="posts/[slug]", to="posts##show")
						.whereSlug("slug")
					.end()

				expect("posts/my-great-post").toMatch(application.wheels.routes[1].regex)
				expect("posts/hello").toMatch(application.wheels.routes[1].regex)
			})

			it("whereIn constrains to a set of values", () => {
				$mapper()
					.$draw()
					.get(name="userByStatus", pattern="users/status/[status]", to="users##byStatus")
						.whereIn("status", "active,inactive,pending")
					.end()

				expect("users/status/active").toMatch(application.wheels.routes[1].regex)
				expect("users/status/inactive").toMatch(application.wheels.routes[1].regex)
				expect("users/status/pending").toMatch(application.wheels.routes[1].regex)
				expect("users/status/deleted").notToMatch(application.wheels.routes[1].regex)
			})

			it("whereMatch applies a custom regex", () => {
				$mapper()
					.$draw()
					.get(name="dated", pattern="archive/[year]", to="archive##show")
						.whereMatch("year", "20\d{2}")
					.end()

				expect("archive/2024").toMatch(application.wheels.routes[1].regex)
				expect("archive/2099").toMatch(application.wheels.routes[1].regex)
				expect("archive/1999").notToMatch(application.wheels.routes[1].regex)
			})

			it("supports comma-delimited variable names", () => {
				$mapper()
					.$draw()
					.get(name="userPost", pattern="users/[userId]/posts/[postId]", to="posts##show")
						.whereNumber("userId,postId")
					.end()

				expect(application.wheels.routes[1].constraints.userId).toBe("\d+")
				expect(application.wheels.routes[1].constraints.postId).toBe("\d+")
			})

			it("throws error when no routes exist", () => {
				mapper = $mapper().$draw()

				expect(function() {
					mapper.whereNumber("id")
				}).toThrow("Wheels.NoRouteToConstrain")
			})
		})

		// -----------------------------------------------------------------------
		// health() tests
		// -----------------------------------------------------------------------
		describe("Tests that health()", () => {

			beforeEach(() => {
				$clearRoutes()
			})

			it("creates a health check route with defaults", () => {
				$mapper()
					.$draw()
					.health()
					.end()

				expect(application.wheels.routes).toHaveLength(1)
				expect(application.wheels.routes[1].pattern).toBe("/health")
				expect(application.wheels.routes[1].name).toBe("health")
			})

			it("creates a health check route with custom handler", () => {
				$mapper()
					.$draw()
					.health(to="monitoring##check")
					.end()

				expect(application.wheels.routes[1].controller).toBe("monitoring")
				expect(application.wheels.routes[1].action).toBe("check")
			})

			it("creates a health check route with custom path", () => {
				$mapper()
					.$draw()
					.health(path="status")
					.end()

				expect(application.wheels.routes[1].pattern).toBe("/status")
			})
		})

		// -----------------------------------------------------------------------
		// Performance index tests
		// -----------------------------------------------------------------------
		describe("Tests that performance indexes", () => {

			beforeEach(() => {
				$clearRoutes()
			})

			it("builds route index by HTTP method", () => {
				$mapper()
					.$draw()
					.get(name="getRoute", to="test##index")
					.post(name="postRoute", to="test##create")
					.end()

				expect(application.wheels).toHaveKey("routeIndex")
				expect(application.wheels.routeIndex).toHaveKey("GET")
				expect(application.wheels.routeIndex).toHaveKey("POST")
			})

			it("indexes static routes for O(1) lookup", () => {
				$mapper()
					.$draw()
					.get(name="login", pattern="login", to="sessions##new")
					.get(name="about", pattern="about", to="pages##about")
					.end()

				expect(application.wheels).toHaveKey("staticRoutes")
				expect(application.wheels.staticRoutes).toHaveKey("GET:/login")
				expect(application.wheels.staticRoutes).toHaveKey("GET:/about")
			})

			it("does not index dynamic routes as static", () => {
				$mapper()
					.$draw()
					.get(name="user", pattern="users/[id]", to="users##show")
					.end()

				// Dynamic routes should not be in staticRoutes
				if (StructKeyExists(application.wheels, "staticRoutes")) {
					for (local.key in application.wheels.staticRoutes) {
						expect(local.key).notToInclude("users/[id]")
					}
				}
			})

			it("marks routes with isStatic flag", () => {
				$mapper()
					.$draw()
					.get(name="about", pattern="about", to="pages##about")
					.get(name="user", pattern="users/[id]", to="users##show")
					.end()

				// First route (about) should be static
				expect(application.wheels.routes[1].isStatic).toBeTrue()
				// Second route (users/[id]) should not be static
				expect(application.wheels.routes[2].isStatic).toBeFalse()
			})

			it("stores pre-compiled regex string on routes", () => {
				$mapper()
					.$draw()
					.get(name="test", pattern="test/[id]", to="test##show")
					.end()

				expect(application.wheels.routes[1]).toHaveKey("regex")
				expect(application.wheels.routes[1].regex).toBeString()
			})
		})
	}

	public struct function $mapper() {
		local.args = Duplicate(config)
		StructAppend(local.args, arguments, true)
		return application.wo.$createObjectFromRoot(argumentCollection = local.args)
	}

	public struct function $inspect() {
		return variables
	}

	public void function $clearRoutes() {
		application.wheels.routes = []
		application.wheels.routeIndex = {}
		application.wheels.staticRoutes = {}
	}

	public boolean function validateRegexPattern(required string pattern) {
		try {
			local.jPattern = CreateObject("java", "java.util.regex.Pattern").compile(arguments.pattern)
		} catch (any e) {
			return false
		}

		return true
	}
}
