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
		.get(name = "packages", pattern = "legacy/[type]/tests", to = "public##packages")
		.get(name = "wheelsPackages", pattern = "legacy/app/tests", to = "public##packages")
		.get(name = "testbox", pattern = "/core/tests", to = "public##tests_testbox")
		.get(name = "migratorTemplates", pattern = "migrator/templates", to = "public##migratortemplates")
		.post(name = "migratorTemplatesCreate", pattern = "migrator/templates", to = "public##migratortemplatescreate")
		.get(name = "migratorSQL", pattern = "migrator/sql/[version]", to = "public##migratorsql")
		.post(name = "migratorCommand", pattern = "migrator/[command]/[version]", to = "public##migratorcommand")
		.get(name = "migrator", pattern = "migrator", to = "public##migrator")
		.get(name = "tests", pattern = "tests/[type]", to = "public##tests")
		.get(name = "apiDocs", pattern = "api", to = "public##api")
		.get(name = "aiDocs", pattern = "ai", to = "public##ai")
		.get(name = "mcp", pattern = "mcp", to = "public##mcp")
		.post(name = "mcpPost", pattern = "mcp", to = "public##mcp")
		.get(name = "cli", pattern = "cli", to = "public##cli")
		.get(name = "pluginEntry", pattern = "plugins/[name]", to = "public##pluginentry")
		.post(name = "pluginPost", pattern = "plugins/[name]", to = "public##pluginentry")
		.get(name = "plugins", pattern = "plugins", to = "public##plugins")
		.get(name = "build", pattern = "build", to = "public##build")
		.get(name = "legacy", pattern = "wheels/[view]", to = "public##legacy")
		.get(name = "guides", pattern = "guides", to = "public##guides")
		.get(name = "guidesWildCard", pattern = "guides/*[path]", to = "public##guides")
		.get(name = "guideImage", pattern = "guides-assets/*[file]", to = "public##guideImage")
		.root(method = "get", to = "public##index", mapFormat = false)
	.end()
	.get(name = "testbox", pattern = "/wheels/app/tests", to = "wheels##public##testbox")
.end();
</cfscript>
