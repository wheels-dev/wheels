component {

	this.name = "WheelsCLITests_" & hash(getCurrentTemplatePath());

	// Map to project root so tests can instantiate cli.lucli.services.* and wheels.wheelstest.*
	local.projectRoot = expandPath("../../../");
	this.mappings["/cli"] = local.projectRoot & "cli/";
	this.mappings["/wheels"] = local.projectRoot & "vendor/wheels/";
	this.mappings["/vendor"] = local.projectRoot & "vendor/";

}
