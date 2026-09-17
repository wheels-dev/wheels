/**
 * Hardener SHOULDs S4 (fix) and S6 (prove). S1/S2/S3/S5 are HELD.
 *
 * Directory-scoped so `wheels test --core --ci --filter=mapper` discovers it.
 *
 * CoS lock: mapper(restful=true, methods=true, mapFormat=true),
 * wildcard method=get / mapKey=false,
 * constraints format=\w+ controller=[^\/]+,
 * health path=health GET.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		config = {path = "wheels", fileName = "Mapper", method = "$init"};
		_originalRoutes = Duplicate(application.wheels.routes);
		_originalStaticRoutes = StructKeyExists(application.wheels, "staticRoutes") ? StructCopy(
			application.wheels.staticRoutes
		) : {};
	}

	function afterAll() {
		application.wheels.routes = _originalRoutes;
		application.wheels.staticRoutes = _originalStaticRoutes;
	}

	function run() {

		describe("CoS lock: mapper public defaults stay conservative", function() {

			it("keeps mapper() restful, methods, and mapFormat true", function() {
				var src = FileRead(ExpandPath("/wheels/global/routing.cfm"));
				expect(FindNoCase("boolean restful = true", src)).toBeGT(0);
				expect(FindNoCase("boolean methods = arguments.restful", src)).toBeGT(0);
				expect(FindNoCase("boolean mapFormat = true", src)).toBeGT(0);
			});

			it("keeps $init restful true and format/controller constraints", function() {
				var src = FileRead(ExpandPath("/wheels/Mapper.cfc"));
				expect(FindNoCase("boolean restful = true", src)).toBeGT(0);
				expect(FindNoCase("boolean mapFormat = true", src)).toBeGT(0);
				expect(FindNoCase("variables.constraints.format = ""\w+""", src)).toBeGT(0);
				expect(FindNoCase("variables.constraints.controller = ""[^\/]+""", src)).toBeGT(0);
			});

			it("keeps wildcard method=get and mapKey=false", function() {
				var src = FileRead(ExpandPath("/wheels/mapper/matching.cfc"));
				expect(FindNoCase("string method = ""get""", src)).toBeGT(0);
				expect(FindNoCase("boolean mapKey = false", src)).toBeGT(0);
			});

			it("keeps health on GET at path=health", function() {
				var src = FileRead(ExpandPath("/wheels/mapper/matching.cfc"));
				expect(FindNoCase("string path = ""health""", src)).toBeGT(0);
				expect(FindNoCase("return get(name = arguments.name, pattern = arguments.path, to = arguments.to)", src)).toBeGT(0);
			});

		});

		describe("S4 restful=false static get does not index POST:/", function() {

			beforeEach(function() {
				$clearRoutes();
			});

			it("does not land POST:/ in staticRoutes for restful=false plus static get", function() {
				$mapper(restful = false)
					.$draw(restful = false)
					.get(name = "home", pattern = "/", to = "pages##home")
					.end();

				expect(application.wheels).toHaveKey("staticRoutes");
				expect(application.wheels.staticRoutes).toHaveKey("GET:/");
				expect(StructKeyExists(application.wheels.staticRoutes, "POST:/")).toBeFalse(
					"restful=false + static get() must not register POST:/ in staticRoutes"
				);
				expect(StructKeyExists(application.wheels.staticRoutes, "PUT:/")).toBeFalse();
				expect(StructKeyExists(application.wheels.staticRoutes, "PATCH:/")).toBeFalse();
				expect(StructKeyExists(application.wheels.staticRoutes, "DELETE:/")).toBeFalse();
			});

			it("does not change restful=true static get indexing", function() {
				$mapper()
					.$draw()
					.get(name = "home", pattern = "/", to = "pages##home")
					.end();

				expect(application.wheels.staticRoutes).toHaveKey("GET:/");
				expect(StructKeyExists(application.wheels.staticRoutes, "POST:/")).toBeFalse(
					"restful=true + static get() must keep POST:/ out of staticRoutes"
				);
			});

		});

		describe("S6 [*path] matches nested paths", function() {

			it("compiles [*path] so /a/b/c matches", function() {
				var mapper = new wheels.Mapper();
				mapper.$init();
				var regex = mapper.$patternToRegex("/[*path]");
				expect(REFindNoCase(regex, "a/b/c")).toBeGT(
					0,
					"compiled [*path] regex must match nested path a/b/c"
				);
				expect(REFindNoCase(regex, "/a/b/c")).toBeGT(
					0,
					"compiled [*path] regex must match /a/b/c"
				);
			});

			it("keeps the glob constraint as .+ so nested segments stay legal", function() {
				var src = FileRead(ExpandPath("/wheels/Mapper.cfc"));
				expect(FindNoCase("variables.constraints[""\*\w+""] = "".+""", src)).toBeGT(
					0,
					"Mapper $init must keep the [*var] glob constraint at .+ (do not tighten)"
				);
			});

		});

	}

	public struct function $mapper() {
		var args = Duplicate(config);
		StructAppend(args, arguments, true);
		return application.wo.$createObjectFromRoot(argumentCollection = args);
	}

	public void function $clearRoutes() {
		application.wheels.routes = [];
		application.wheels.staticRoutes = {};
	}

}
