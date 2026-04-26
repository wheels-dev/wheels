component {

	this.name = "WheelsCLITests_" & hash(getCurrentTemplatePath());

	// Map to project root so tests can instantiate modules.wheels.services.* and wheels.wheelstest.*
	local.projectRoot = expandPath("../../../");
	this.mappings["/cli"] = local.projectRoot & "cli/";
	this.mappings["/wheels"] = local.projectRoot & "vendor/wheels/";
	this.mappings["/vendor"] = local.projectRoot & "vendor/";

}
