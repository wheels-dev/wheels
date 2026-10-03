<cfscript>
// IIS test job fixture (tools/ci/iis): copied over the app's config/routes.cfm on the runner.
mapper()
	.get(name = "probeHello", pattern = "probe/hello", to = "probes##hello")
	.get(name = "probeNested", pattern = "probe/[id]/items/[itemId]", to = "probes##nested")
	// A route whose name starts like a static folder (files/...): it must still reach the router.
	.get(name = "probeFilesGallery", pattern = "files-gallery", to = "probes##hello")
	.wildcard()
	.root(method = "get")
	.end();
</cfscript>
