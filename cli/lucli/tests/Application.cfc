component {

	this.name = "WheelsCLITests_" & hash(getCurrentTemplatePath());

	// Map to project root so tests can instantiate modules.wheels.services.* and wheels.wheelstest.*
	local.projectRoot = expandPath("../../../");
	this.mappings["/cli"] = local.projectRoot & "cli/";
	this.mappings["/wheels"] = local.projectRoot & "vendor/wheels/";
	this.mappings["/vendor"] = local.projectRoot & "vendor/";

	// At runtime, LuCLI exposes the wheels module under the dotted path
	// `modules.wheels.X` (because LuCLI's executeModule.cfs uses
	// createObject("component", "modules.<name>.Module") to load each module).
	// Production code under cli/lucli/ uses that same prefix to refer to its
	// own services so the dotted paths resolve in every install context
	// (dev symlink, brew bottle, choco package). Tests need the matching
	// mapping so spec files can also use modules.wheels.services.* refs.
	this.mappings["/modules/wheels"] = local.projectRoot & "cli/lucli/";

}
