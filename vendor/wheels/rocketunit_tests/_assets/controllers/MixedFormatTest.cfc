component extends="Controller" {

	function config() {
		// This controller provides multiple formats
		provides("html,json,xml");
	}

	// HTML action - should still require a view
	function htmlAction() {
		// This should throw ViewNotFound if no view exists
	}

	// JSON action with renderText
	function jsonWithRenderText() {
		renderText('{"source":"renderText"}');
	}

	// JSON action with renderWith
	function jsonWithRenderWith() {
		renderWith(data = {source = "renderWith", items = [1, 2, 3]});
	}

	// Action that checks format and renders accordingly
	function formatAware() {
		local.format = $requestContentType();
		
		if (local.format == "html") {
			// For HTML, let it look for a view
		} else if (local.format == "json") {
			renderText('{"format":"json"}');
		} else if (local.format == "xml") {
			renderText('<format>xml</format>');
		}
	}

	// Action restricted to specific formats
	function restrictedFormats() {
		onlyProvides("json,xml");
		renderWith(data = {restricted = true});
	}

}