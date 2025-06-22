component extends="Controller" {

	function config() {
		// This controller only provides JSON and XML, no HTML
		onlyProvides("json,xml");
	}

	// Test action that uses renderText with JSON
	function renderTextJson() {
		renderText('{"success":true,"message":"renderText JSON works!"}');
	}

	// Test action that uses renderText with XML
	function renderTextXml() {
		renderText('<?xml version="1.0" encoding="UTF-8"?><response><success>true</success><message>renderText XML works!</message></response>');
	}

	// Test action that uses renderWith to auto-generate JSON
	function renderWithJson() {
		local.data = {
			success = true,
			message = "renderWith JSON works!",
			timestamp = Now(),
			nested = {
				value = 123,
				array = [1, 2, 3]
			}
		};
		renderWith(data = local.data);
	}

	// Test action that uses renderWith to auto-generate XML
	function renderWithXml() {
		local.data = {
			success = true,
			message = "renderWith XML works!",
			timestamp = Now()
		};
		renderWith(data = local.data);
	}

	// Test action that doesn't render anything - should not throw error
	function noRender() {
		// This action does nothing, but should not throw ViewNotFound error
		// because we're in a JSON/XML only controller
	}

	// Test action with custom status code
	function renderWithStatus() {
		renderText('{"error":"Not Found"}', status = 404);
	}

}