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
	
	/* 
		To fix the issue below:
		https://github.com/wheels-dev/wheels/issues/1132
		
		To add the test framework functions in the documentation. Added the Test componenet in the documentscope.

		As app/test/functions/Example.cfc can be deleted, so check if that component exists then create that component's object.
		As Example.cfc extends tests.Test so we are checking the Example.cfc first as that will include both component's functions.
	*/
	try{
		// BoxLang compatibility: Use correct component path
		if (StructKeyExists(server, "boxlang")) {
			ArrayAppend(documentScope, {"name" = "test", "scope" = CreateObject("component", "wheels.tests.functions.Example")});
		} else {
			ArrayAppend(documentScope, {"name" = "test", "scope" = CreateObject("component", "tests.functions.Example")});
		}
	}
	catch (any exception){
		// BoxLang compatibility: Use correct component path
		if (StructKeyExists(server, "boxlang")) {
			ArrayAppend(documentScope, {"name" = "test", "scope" = CreateObject("component", "wheels.tests.Test")});
		} else {
			ArrayAppend(documentScope, {"name" = "test", "scope" = CreateObject("component", "tests.Test")});
		}
	}

	ArrayAppend(documentScope, {"name" = "mapper", "scope" = application.wheels.mapper});
	if (application.wheels.enablePluginsComponent) {
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

include "layouts/#request.wheels.params.format#.cfm";
</cfscript>
