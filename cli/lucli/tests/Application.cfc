component {

	this.name = "WheelsCLITests_" & hash(getCurrentTemplatePath());

	// Map to project root so tests can instantiate cli.lucli.services.* and
	// wheels.wheelstest.* via the absolute dotted paths the spec files use.
	local.projectRoot = expandPath("../../../");
	this.mappings["/cli"] = local.projectRoot & "cli/";
	this.mappings["/wheels"] = local.projectRoot & "vendor/wheels/";
	this.mappings["/vendor"] = local.projectRoot & "vendor/";

	// At runtime LuCLI exposes the wheels module under the `modules.wheels.X`
	// dotted path (LuCLI's executeModule.cfs does
	// `createObject("component", "modules.<name>.Module")` to load each module).
	// Production code under cli/lucli/services/ uses that prefix so its own
	// internal refs resolve in every install context (dev symlink, brew bottle,
	// choco package). Spec files load services via `cli.lucli.X` (above) — but
	// once a service is instantiated, its INTERNAL refs are `modules.wheels.X`,
	// so we mirror LuCLI's runtime mapping here to keep cross-service calls
	// resolvable inside the test runner.
	this.mappings["/modules/wheels"] = local.projectRoot & "cli/lucli/";

	// Test double for LuCLI's modules.BaseModule under TestBox — see #2829 / PR #2831.
	this.mappings["/modules"] = local.projectRoot & "cli/lucli/tests/_modules/";

}
