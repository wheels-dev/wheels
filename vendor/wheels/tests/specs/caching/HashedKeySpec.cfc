/**
 * `$hashedKey()` must give equal keys only for equal inputs: struct key order and key case are
 * ignored, while argument names, positional order, array element order and query row / cell
 * order all distinguish keys.
 *
 * Directory-scoped so `wheels test --core --ci --filter=caching` discovers this folder.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo

		describe("$hashedKey() distinguishes inputs", function() {

			it("distinguishes swapped positional values", function() {
				expect(g.$hashedKey(3, 4)).notToBe(g.$hashedKey(4, 3));
			});

			it("distinguishes swapped named values", function() {
				expect(g.$hashedKey(a = 3, b = 4)).notToBe(g.$hashedKey(a = 4, b = 3));
			});

			it("distinguishes argument names", function() {
				expect(g.$hashedKey(a = 3)).notToBe(g.$hashedKey(z = 3));
			});

			it("distinguishes array element order", function() {
				expect(g.$hashedKey([3, 4])).notToBe(g.$hashedKey([4, 3]));
				expect(g.$hashedKey(ids = [3, 4])).notToBe(g.$hashedKey(ids = [4, 3]));
			});

			it("distinguishes a list string from an array of its items", function() {
				expect(g.$hashedKey("a,b")).notToBe(g.$hashedKey(["a", "b"]));
			});

			it("distinguishes comma-separated segments moved inside a string", function() {
				var first = g.$hashedKey("S", "id IN (1,2,3) AND id NOT IN (4,5,6)");
				var second = g.$hashedKey("S", "id IN (1,5,3) AND id NOT IN (4,2,6)");
				expect(first).notToBe(second);
			});

			it("distinguishes query cells swapped between rows", function() {
				var first = QueryNew("id,name", "integer,varchar", [[1, "alice"], [2, "bob"]]);
				var second = QueryNew("id,name", "integer,varchar", [[1, "bob"], [2, "alice"]]);
				expect(g.$hashedKey(first)).notToBe(g.$hashedKey(second));
				expect(g.$hashedKey(rows = first)).notToBe(g.$hashedKey(rows = second));
			});

			it("distinguishes nested struct values swapped between keys", function() {
				var first = {user = {id = 313}, viewer = {id = 414}};
				var second = {user = {id = 414}, viewer = {id = 313}};
				expect(g.$hashedKey(first)).notToBe(g.$hashedKey(second));
			});

			it("distinguishes model objects with different property values", function() {
				var first = g.model("author").new(firstName = "Per", lastName = "Djurner");
				var second = g.model("author").new(firstName = "Djurner", lastName = "Per");
				expect(g.$hashedKey(object = first)).notToBe(g.$hashedKey(object = second));
			});

		});

		describe("$hashedKey() stays stable for equal inputs", function() {

			it("ignores struct key insertion order", function() {
				var first = {};
				first.b = 2;
				first.a = 1;
				first.c = {y = 2, x = 1};
				var second = {};
				second.c = {x = 1, y = 2};
				second.a = 1;
				second.b = 2;
				expect(g.$hashedKey(first)).toBe(g.$hashedKey(second));
			});

			it("ignores struct key case", function() {
				var first = {};
				first["NAME"] = "per";
				var second = {};
				second["name"] = "per";
				expect(g.$hashedKey(first)).toBe(g.$hashedKey(second));
			});

			it("gives equal queries equal keys", function() {
				var first = QueryNew("id,name", "integer,varchar", [[1, "alice"], [2, "bob"]]);
				var second = QueryNew("id,name", "integer,varchar", [[1, "alice"], [2, "bob"]]);
				expect(g.$hashedKey(rows = first)).toBe(g.$hashedKey(rows = second));
			});

			it("gives the same model object the same key", function() {
				var author = g.model("author").new(firstName = "Per", lastName = "Djurner");
				expect(g.$hashedKey(object = author)).toBe(g.$hashedKey(object = author));
			});

			it("accepts binary values", function() {
				var binaryData = FileReadBinary(ExpandPath("/wheels/tests/_assets/files/wheels-logo.png"));
				var args = {data = binaryData, list = [1, 2, 3]};
				expect(g.$hashedKey(argumentCollection = args)).toBe(g.$hashedKey(argumentCollection = args));
			});

		});

		describe("Partial cache with query arguments", function() {

			beforeEach(function() {
				variables.savedCachePartials = application.wheels.cachePartials;
				application.wheels.cachePartials = true;
				g.$clearCache("partial");
				request.cachedRowsRenders = 0;
			});

			afterEach(function() {
				g.$clearCache("partial");
				application.wheels.cachePartials = variables.savedCachePartials;
			});

			it("renders a query whose cells are swapped between rows instead of serving the cached output", function() {
				var c = g.controller("test", {controller = "test", action = "index"});
				var first = QueryNew("id,name", "integer,varchar", [[1, "alice"], [2, "bob"]]);
				var second = QueryNew("id,name", "integer,varchar", [[1, "bob"], [2, "alice"]]);
				request.wheels.includePartialStack = [];
				var firstOutput = Trim(c.includePartial(partial = "cachedrows", cache = 5, rows = first));
				request.wheels.includePartialStack = [];
				var secondOutput = Trim(c.includePartial(partial = "cachedrows", cache = 5, rows = second));
				expect(firstOutput).toBe("1:alice|2:bob|");
				expect(secondOutput).toBe("1:bob|2:alice|");
				expect(request.cachedRowsRenders).toBe(2);
			});

			it("serves the cached output for an equal query", function() {
				var c = g.controller("test", {controller = "test", action = "index"});
				var first = QueryNew("id,name", "integer,varchar", [[1, "alice"], [2, "bob"]]);
				var second = QueryNew("id,name", "integer,varchar", [[1, "alice"], [2, "bob"]]);
				request.wheels.includePartialStack = [];
				var firstOutput = Trim(c.includePartial(partial = "cachedrows", cache = 5, rows = first));
				request.wheels.includePartialStack = [];
				var cachedOutput = Trim(c.includePartial(partial = "cachedrows", cache = 5, rows = second));
				expect(cachedOutput).toBe(firstOutput);
				expect(request.cachedRowsRenders).toBe(1);
			});

		});

	}

}
