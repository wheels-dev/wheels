/**
 * The strictArguments setting reports arguments a framework declaration doesn't know (a typo, a
 * name from another framework) instead of ignoring them silently: "warn" logs one wheels.log line
 * per class, function and argument, "throw" raises Wheels.UnknownArgument, "off" does nothing.
 * Only functions with a fixed set of arguments are checked. The declaration specs use "throw",
 * which fails before anything is registered, so no shared model class is changed.
 */
component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.g = application.wo;
		variables.migration = CreateObject("component", "wheels.migrator.Migration").init();
	}

	function saveStrictState() {
		variables.saved = {
			mode = StructKeyExists(application.wheels, "strictArguments") ? application.wheels.strictArguments : "off",
			seen = StructKeyExists(application.wheels, "$strictArgumentsSeen") ? application.wheels.$strictArgumentsSeen : {}
		};
		application.wheels.$strictArgumentsSeen = {};
	}

	function restoreStrictState() {
		application.wheels.strictArguments = variables.saved.mode;
		application.wheels.$strictArgumentsSeen = variables.saved.seen;
	}

	function useMode(required string mode) {
		application.wheels.strictArguments = arguments.mode;
	}

	// The type and message of what `callback` throws, or empty strings.
	function failureOf(required any callback) {
		var state = {type = "", message = ""};
		var target = arguments.callback;
		try {
			target();
		} catch (any e) {
			state.type = e.type;
			state.message = e.message;
		}
		return state;
	}

	function run() {

		describe("strictArguments", () => {

		beforeEach(() => {
			saveStrictState();
		});

		afterEach(() => {
			restoreStrictState();
		});

		describe("strictArguments = throw", () => {

			it("rejects an unknown association argument and suggests the right name", () => {
				useMode("throw");
				var author = variables.g.model("author");
				var failure = failureOf(() => author.hasMany(name = "posts", foreign_key = "authorid"));
				expect(failure.type).toBe("Wheels.UnknownArgument");
				expect(failure.message).toInclude("hasMany()");
				expect(failure.message).toInclude("foreign_key");
				expect(failure.message).toInclude("Did you mean `foreignKey`");
			});

			it("rejects unknown arguments to validations and callback registration", () => {
				useMode("throw");
				var author = variables.g.model("author");
				expect(failureOf(() => author.validatesPresenceOf(properties = "firstName", mesage = "x")).type).toBe("Wheels.UnknownArgument");
				expect(failureOf(() => author.beforeSave(methods = "callbackThatReturnsTrue", on = "create")).type).toBe("Wheels.UnknownArgument");
				expect(failureOf(() => author.afterCommit(method = "callbackThatReturnsTrue")).message).toInclude("Did you mean `methods`");
			});

			it("accepts the documented aliases", () => {
				useMode("throw");
				var author = variables.g.model("author");
				var accepted = author.$strictArgumentsAccepted("validatesLengthOf");
				expect(failureOf(() => author.$checkArguments(args = {property = "firstName", minimum = 1}, name = "validatesLengthOf", accepted = accepted)).type).toBe("");
				expect(failureOf(() => author.$args(args = {associations = "profile"}, name = "nestedProperties", combine = "association/associations")).type).toBe("");
			});

			it("names the finder the app called", () => {
				useMode("throw");
				var author = variables.g.model("author");
				expect(failureOf(() => author.findAll(orderby = "lastName")).message).toInclude("Did you mean `order`");
				expect(failureOf(() => author.findOne(orderby = "lastName")).message).toInclude("findOne()");
				expect(failureOf(() => author.findOneByFirstName(value = "Per", orderby = "lastName")).message).toInclude("findOneByFirstName()");
			});

			it("lets the finders' own options and internal forwarding through", () => {
				useMode("throw");
				var author = variables.g.model("author");
				expect(failureOf(() => author.findAll(order = "lastName", returnType = "query")).type).toBe("");
				expect(failureOf(() => author.findOneByFirstName(firstName = "Per")).type).toBe("");
				expect(failureOf(() => author.count()).type).toBe("");
				expect(failureOf(() => author.exists(where = "firstName = 'Per'")).type).toBe("");
				expect(failureOf(() => author.findFirst(property = "lastName")).type).toBe("");
				expect(failureOf(() => author.findLastOne(properties = "lastName")).type).toBe("");
			});

			it("rejects an unknown column option in a migration", () => {
				useMode("throw");
				var t = variables.migration.createTable(name = "c_o_r_e_strictargs", force = true);
				var failure = failureOf(() => t.string(columnNames = "title", nullable = true));
				expect(failure.type).toBe("Wheels.UnknownArgument");
				expect(failure.message).toInclude("Did you mean `allowNull`");
				expect(failureOf(() => t.string(columnNames = "title", allowNull = true, limit = 50, default = "")).type).toBe("");
				expect(failureOf(() => t.bigInteger(columnName = "views", unsigned = true)).type).toBe("");
			});

			it("accepts null, the deprecated column option, without warning", () => {
				useMode("throw");
				var t = variables.migration.createTable(name = "c_o_r_e_strictargs", force = true);
				// `null` is a keyword on some engines, so it goes in through argumentCollection.
				var options = {columnNames = "title"};
				options["null"] = false;
				expect(failureOf(() => t.string(argumentCollection = options)).type).toBe("");
				expect(t.columns[ArrayLen(t.columns)].allowNull).toBeFalse();
				useMode("warn");
				var more = {columnNames = "summary"};
				more["null"] = false;
				t.string(argumentCollection = more);
				expect(StructCount(application.wheels.$strictArgumentsSeen)).toBe(0);
			});

			it("doesn't check functions that turn unknown arguments into something", () => {
				useMode("throw");
				expect(variables.g.$strictArgumentsSource("linkTo")).toBe("");
				expect(variables.g.$strictArgumentsSource("create")).toBe("");
				expect(variables.g.$strictArgumentsSource("filters")).toBe("");
				expect(variables.g.$strictArgumentsSource("hasMany")).toBe("model");
			});

			it("ignores positional and internal arguments", () => {
				useMode("throw");
				var author = variables.g.model("author");
				var args = {name = "posts"};
				args["1"] = "posts";
				args["$internal"] = true;
				expect(failureOf(() => author.$checkArguments(args = args, name = "hasMany")).type).toBe("");
			});

		});

		describe("strictArguments = warn", () => {

			it("records an unknown argument once per class, function and argument, without throwing", () => {
				useMode("warn");
				var author = variables.g.model("author");
				var first = failureOf(() => author.$checkArguments(args = {name = "posts", foreign_key = "x"}, name = "hasMany"));
				var second = failureOf(() => author.$checkArguments(args = {name = "posts", foreign_key = "x"}, name = "hasMany"));
				expect(first.type).toBe("");
				expect(second.type).toBe("");
				expect(StructCount(application.wheels.$strictArgumentsSeen)).toBe(1);
				expect(StructKeyList(application.wheels.$strictArgumentsSeen)).toInclude("foreign_key");
			});

			it("stops recording once the cap is reached", () => {
				useMode("warn");
				var author = variables.g.model("author");
				var full = {};
				for (var i = 1; i <= author.$strictArgumentsSeenCap(); i++) {
					full["filler|hasMany|arg#i#"] = true;
				}
				application.wheels.$strictArgumentsSeen = full;
				StructDelete(application.wheels, "$strictArgumentsCapped");
				var failure = failureOf(() => author.$checkArguments(args = {name = "posts", foreign_key = "x"}, name = "hasMany"));
				expect(failure.type).toBe("");
				expect(StructCount(application.wheels.$strictArgumentsSeen)).toBe(author.$strictArgumentsSeenCap());
				expect(StructKeyExists(application.wheels, "$strictArgumentsCapped")).toBeTrue();
				StructDelete(application.wheels, "$strictArgumentsCapped");
			});

			it("reports a finder argument once, under the finder the app called", () => {
				useMode("warn");
				var author = variables.g.model("author");
				author.findOne(orderby = "lastName");
				expect(StructCount(application.wheels.$strictArgumentsSeen)).toBe(1);
			});

		});

		describe("strictArguments = off", () => {

			it("ignores unknown arguments", () => {
				useMode("off");
				var author = variables.g.model("author");
				expect(failureOf(() => author.$checkArguments(args = {name = "posts", foreign_key = "x"}, name = "hasMany")).type).toBe("");
				expect(failureOf(() => author.findAll(orderby = "lastName")).type).toBe("");
				expect(StructCount(application.wheels.$strictArgumentsSeen)).toBe(0);
			});

		});

		describe("The strictArguments default", () => {

			it("is off outside development", () => {
				expect(variables.saved.mode).toBe(variables.g.get("environment") == "development" ? "warn" : "off");
			});

		});

		});

	}

}
