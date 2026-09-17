/** Execute generated show markup without a database or the Wheels renderer. */
component {
	public string function render(required string templatePath, required string parentVar, required struct record) {
		variables[arguments.parentVar] = arguments.record;
		// Absolute physical include paths can be interpreted as webroot-relative.
		// Include a unique sibling instead, without changing application mappings.
		var fileName = "_related-block-" & Replace(CreateUUID(), "-", "", "all") & ".cfm";
		var temporaryPath = GetDirectoryFromPath(GetCurrentTemplatePath()) & fileName;
		try {
			FileCopy(arguments.templatePath, temporaryPath);
			savecontent variable="local.rendered" {
				include template="#fileName#";
			}
			return local.rendered;
		} finally {
			if (FileExists(temporaryPath)) FileDelete(temporaryPath);
		}
	}

	/** A deterministic link stand-in so assertions count rendered record links. */
	public string function linkTo(required string route, required string text, string key = "") {
		return "[" & arguments.route & ":" & arguments.key & ":" & arguments.text & "]";
	}
}
