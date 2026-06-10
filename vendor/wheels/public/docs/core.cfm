<cfscript>
// Core API embedded documentation

param name="request.wheels.params.type" default="core";
param name="request.wheels.params.format" default="html";

if (StructKeyExists(application.wheels, "docs")) {
	docs = application.wheels.docs;
} else {
	documentScope = [];

	// Plugins First, as they can potentially hijack an internal function
	if (application.wheels.enablePluginsComponent) {
		for (local.plugin in application.wheels.plugins) {
			ArrayAppend(documentScope, {"name" = local.plugin, "scope" = application.wheels.plugins[local.plugin]});
		}
	}

	controllerInstance = CreateObject("component", "app.controllers.Controller").init();
	// Remove functions starting with "super"
	for (key in structKeyArray(controllerInstance)) {
		if ((isCustomFunction(controllerInstance[key]) || isClosure(controllerInstance[key])) &&
			left(lCase(key), 5) == "super") {
			structDelete(controllerInstance, key);
		}
	}

	ArrayAppend(documentScope, {"name" = "controller", "scope" = controllerInstance});

	modelInstance = CreateObject("component", "app.models.Model").init();
	// Remove functions starting with "super"
	for (key in structKeyArray(modelInstance)) {
		if ((isCustomFunction(modelInstance[key]) || isClosure(modelInstance[key])) &&
			left(lCase(key), 5) == "super") {
			structDelete(modelInstance, key);
		}
	}

	// Now safely append to documentScope
	ArrayAppend(documentScope, {"name" = "model", "scope" = modelInstance});
	
	ArrayAppend(documentScope, {"name" = "mapper", "scope" = application.wheels.mapper});
	if (application.wheels.enableMigratorComponent) {
		ArrayAppend(documentScope, {"name" = "migrator", "scope" = application.wheels.migrator});
		ArrayAppend(
			documentScope,
			{"name" = "migration", "scope" = CreateObject("component", "wheels.migrator.Migration")}
		);
		ArrayAppend(
			documentScope,
			{"name" = "tabledefinition", "scope" = CreateObject("component", "wheels.migrator.TableDefinition")}
		);
	}
	// Array of functions to ignore
	ignore = [
		"config",
		"init",
		"onDIcomplete",
		"exposeMixin",
		"getPropertyMixin",
		"getVariablesMixin",
		"includeitMixin",
		"injectMixin",
		"injectPropertyMixin",
		"invokerMixin",
		"methodProxy",
		"removeMixin",
		"removePropertyMixin"
	];

	// Populate the main documentation
	docs = $returnInternalDocumentation(documentScope, ignore);

	application.wheels.docs = docs;
}

// Validate `format` against an alphanumeric allowlist before interpolating
// it into the include path. Without this, `format=../views/info` would
// climb out of layouts/ — same LFI traversal class $getRequestFormat was
// hardened against (issue #2974).
local.docFormat = $resolveDocFormat(request.wheels.params.format);
include "layouts/#local.docFormat#.cfm";
</cfscript>
