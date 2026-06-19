component extends="wheels.WheelsTest" {

	function run() {

		describe("config() override without super.config() detection", () => {

			it("flags a controller that overrides config() without calling super.config()", () => {
				local.c = application.wo.controller(
					name = "configchain.NoSuper",
					params = {controller = "configchain.NoSuper", action = "index"}
				);
				expect(local.c.$configOverrideSkipsSuper()).toBeTrue();
			});

			it("does not flag a controller whose config() calls super.config()", () => {
				local.c = application.wo.controller(
					name = "configchain.WithSuper",
					params = {controller = "configchain.WithSuper", action = "index"}
				);
				expect(local.c.$configOverrideSkipsSuper()).toBeFalse();
			});

			it("flags a controller whose super.config() call is commented out", () => {
				local.c = application.wo.controller(
					name = "configchain.CommentedSuper",
					params = {controller = "configchain.CommentedSuper", action = "index"}
				);
				expect(local.c.$configOverrideSkipsSuper()).toBeTrue();
			});

			it("does not flag a controller that inherits config() without overriding it", () => {
				local.c = application.wo.controller(
					name = "configchain.InheritsOnly",
					params = {controller = "configchain.InheritsOnly", action = "index"}
				);
				expect(local.c.$configOverrideSkipsSuper()).toBeFalse();
			});

			it("does not flag a controller whose config() has no ancestor config() to shadow", () => {
				// The Test asset controller declares config() but its parent (the asset
				// base Controller.cfc) declares none, so nothing is shadowed.
				local.c = application.wo.controller(
					name = "Test",
					params = {controller = "Test", action = "test"}
				);
				expect(local.c.$configOverrideSkipsSuper()).toBeFalse();
			});

		});

		describe("config() override warning registration", () => {

			beforeEach(() => {
				variables.origEnv = application.wheels.environment;
				StructDelete(application.wheels, "controllerConfigWarnings");
				StructDelete(application.wheels.controllers, "configchain.NoSuperWiring");
			});

			afterEach(() => {
				application.wheels.environment = variables.origEnv;
				StructDelete(application.wheels, "controllerConfigWarnings");
				StructDelete(application.wheels.controllers, "configchain.NoSuperWiring");
			});

			it("registers a development-mode warning at controller class init", () => {
				application.wheels.environment = "development";
				application.wo.controller(
					name = "configchain.NoSuperWiring",
					params = {controller = "configchain.NoSuperWiring", action = "index"}
				);
				expect(StructKeyExists(application.wheels, "controllerConfigWarnings")).toBeTrue();
				expect(ArrayLen(application.wheels.controllerConfigWarnings)).toBe(1);
				expect(application.wheels.controllerConfigWarnings[1].controller).toBe("configchain.NoSuperWiring");
			});

			it("dedupes repeated warnings for the same controller", () => {
				application.wheels.environment = "development";
				local.c = application.wo.controller(
					name = "configchain.NoSuperWiring",
					params = {controller = "configchain.NoSuperWiring", action = "index"}
				);
				local.c.$warnIfConfigSkipsSuper();
				local.c.$warnIfConfigSkipsSuper();
				expect(ArrayLen(application.wheels.controllerConfigWarnings)).toBe(1);
			});

			it("does not register a warning outside the development environment", () => {
				application.wheels.environment = "production";
				application.wo.controller(
					name = "configchain.NoSuperWiring",
					params = {controller = "configchain.NoSuperWiring", action = "index"}
				);
				local.registered = StructKeyExists(application.wheels, "controllerConfigWarnings")
					&& ArrayLen(application.wheels.controllerConfigWarnings) > 0;
				expect(local.registered).toBeFalse();
			});

		});

	}

}
