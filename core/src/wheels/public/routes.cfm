<cfscript>
/**
 * Internal GUI Routes
 * TODO: formalise how the cli interacts
 **/
mapper()
	.namespace(name = "wheels")
		.get(name = "info", pattern = "info", to = "public##info")
		.get(name = "routes", pattern = "routes", to = "public##routes")
		.post(name = "routeTester", to = "public##routetester")
		.get(name = "runner", pattern = "runner", to = "public##runner")
		.get(name = "packages", pattern = "packages/[type]", to = "public##packages")
		.get(name = "wheelsPackages", pattern = "packages/app", to = "public##packages")
		.get(name = "wheelstestbox", pattern = "testbox", to = "public##tests_testbox")
		.get(name = "wheelsapptests", pattern = "app-tests", to = "public##app_tests")
		.get(name = "migratorTemplates", pattern = "migrator/templates", to = "public##migratortemplates")
		.post(name = "migratorTemplatesCreate", pattern = "migrator/templates", to = "public##migratortemplatescreate")
		.get(name = "migratorSQL", pattern = "migrator/sql/[version]", to = "public##migratorsql")
		.post(name = "migratorCommand", pattern = "migrator/[command]/[version]", to = "public##migratorcommand")
		.get(name = "migrator", pattern = "migrator", to = "public##migrator")
		.get(name = "tests", pattern = "tests/[type]", to = "public##tests")
		.get(name = "docs", pattern = "docs", to = "public##docs")
		.get(name = "cli", pattern = "cli", to = "public##cli")
		.get(name = "pluginEntry", pattern = "plugins/[name]", to = "public##pluginentry")
		.post(name = "pluginPost", pattern = "plugins/[name]", to = "public##pluginentry")
		.get(name = "plugins", pattern = "plugins", to = "public##plugins")
		.get(name = "build", pattern = "build", to = "public##build")
		.get(name = "legacy", pattern = "wheels/[view]", to = "public##legacy")
		.root(method = "get", to = "public##index", mapFormat = false)
	.end()
	// Add route for tests controller outside the wheels namespace
	.get(name = "testsController", pattern = "tests", to = "tests##index")
.end();
</cfscript>
