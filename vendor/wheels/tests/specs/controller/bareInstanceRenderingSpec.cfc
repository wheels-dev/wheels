component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("$generateIncludeTemplatePath on a bare controller instance", () => {

			beforeEach(() => {
				// A bare-instantiated controller has never gone through the request
				// lifecycle, so `variables.params` is never set — init() only runs
				// $integrateComponents. This mirrors `new wheels.Controller()`.
				bareController = CreateObject("component", "wheels.Controller").init();
			});

			it("resolves an absolute template path without dereferencing variables.params", () => {
				// Absolute paths never use the controller name, so the default-arg
				// dereference of `variables.params.controller` must not fire here.
				actual = "";
				expect(function() {
					actual = bareController.$generateIncludeTemplatePath($name = "/mailers/welcome", $type = "email");
				}).notToThrow();

				expect(actual).toInclude("/mailers/welcome.cfm");
			});

			it("throws a clear named error for a controller-relative template path", () => {
				// A no-leading-slash path needs controller-relative resolution. On a
				// bare instance there is no controller name, so it must surface a clear
				// named error rather than the raw PARAMS dereference crash.
				expect(function() {
					bareController.$generateIncludeTemplatePath($name = "welcome", $type = "email");
				}).toThrow("Wheels.ControllerNameRequired");
			});

			it("throws a clear named error for a current-controller subfolder path", () => {
				expect(function() {
					bareController.$generateIncludeTemplatePath($name = "mailers/welcome", $type = "email");
				}).toThrow("Wheels.ControllerNameRequired");
			});
		});

		describe("$generateIncludeTemplatePath on a request-built controller (no behavior change)", () => {

			beforeEach(() => {
				params = {controller = "test", action = "test"};
				_controller = g.controller("test", params);
			});

			it("still resolves controller-relative templates using params.controller", () => {
				actual = _controller.$generateIncludeTemplatePath($name = "welcome", $type = "email");

				expect(actual).toInclude("/test/welcome.cfm");
			});

			it("still resolves absolute templates", () => {
				actual = _controller.$generateIncludeTemplatePath($name = "/mailers/welcome", $type = "email");

				expect(actual).toInclude("/mailers/welcome.cfm");
			});
		});
	}
}
