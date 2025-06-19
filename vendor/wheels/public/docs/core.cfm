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

	ArrayAppend(documentScope, {"name" = "controller", "scope" = CreateObject("component", "app.controllers.Controller").init()});
	ArrayAppend(documentScope, {"name" = "model", "scope" = CreateObject("component", "app.models.Model").init()});
	
	/* 
		To fix the issue below:
		https://github.com/cfwheels/cfwheels/issues/1132
		
		To add the test framework functions in the documentation. Added the Test componenet in the documentscope.

		As app/test/functions/Example.cfc can be deleted, so check if that component exists then create that component's object.
		As Example.cfc extends tests.Test so we are checking the Example.cfc first as that will include both component's functions.
	*/
	try{
		ArrayAppend(documentScope, {"name" = "test", "scope" = CreateObject("component", "tests.functions.Example")});
	}
	catch (any exception){
		ArrayAppend(documentScope, {"name" = "test", "scope" = CreateObject("component", "tests.Test")});
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
	ignore = ["config", "init"];

	// Populate the main documentation
	docs = $returnInternalDocumentation(documentScope, ignore);

	application.wheels.docs = docs;
}

include "layouts/#request.wheels.params.format#.cfm";
</cfscript>
