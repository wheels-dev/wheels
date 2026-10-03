<cfscript>
// IIS test job fixture (tools/ci/iis): copied over the app's config/routes.cfm on the runner.
mapper()
	.get(name = "probeHello", pattern = "probe/hello", to = "probes##hello")
	.get(name = "probeNested", pattern = "probe/[id]/items/[itemId]", to = "probes##nested")
	.wildcard()
	.root(method = "get")
	.end();
</cfscript>
