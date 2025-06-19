/**
 * Find matching route for a given URL
 *
 * {code:bash}
 * wheels routes:match /users
 * wheels routes:match /users/123
 * wheels routes:match /users/123/edit
 * wheels routes:match /products method=POST
 * {code}
 */
component extends="../base" {

	/**
	 * @url The URL path to match
	 * @method HTTP method (default: GET)
	 * @help Find which route matches a given URL
	 */
	public void function run(required string url, string method = "GET") {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		try {
			// Get all routes
			local.routes = getRoutes(local.appPath);
			
			if (ArrayLen(local.routes) == 0) {
				print.yellowLine("No routes found in the application");
				return;
			}
			
			// Normalize the URL
			local.normalizedUrl = arguments.url;
			if (!Left(local.normalizedUrl, 1) == "/") {
				local.normalizedUrl = "/" & local.normalizedUrl;
			}
			
			// Find matching routes
			local.matches = [];
			for (local.route in local.routes) {
				if (routeMatches(local.route, local.normalizedUrl, arguments.method)) {
					ArrayAppend(local.matches, local.route);
				}
			}
			
			if (ArrayLen(local.matches) == 0) {
				print.redLine("No routes match URL: " & arguments.url & " [" & arguments.method & "]");
				return;
			}
			
			// Display matches
			print.line();
			print.boldGreenLine("Matching route found!");
			print.line();
			
			// Show the best match (first one)
			local.bestMatch = local.matches[1];
			print.yellowLine("URL: " & arguments.url & " [" & arguments.method & "]");
			print.line();
			
			if (StructKeyExists(local.bestMatch, "name") && Len(local.bestMatch.name)) {
				print.cyanLine("Route Name: " & local.bestMatch.name);
			}
			print.cyanLine("Pattern: " & local.bestMatch.pattern);
			print.cyanLine("Controller: " & local.bestMatch.controller);
			print.cyanLine("Action: " & local.bestMatch.action);
			
			// Extract parameters if any
			local.params = extractParameters(local.bestMatch.pattern, local.normalizedUrl);
			if (!StructIsEmpty(local.params)) {
				print.line();
				print.boldLine("Parameters:");
				for (local.key in local.params) {
					print.cyanLine("  " & local.key & ": " & local.params[local.key]);
				}
			}
			
			// Show other possible matches
			if (ArrayLen(local.matches) > 1) {
				print.line();
				print.yellowLine("Other possible matches:");
				for (local.i = 2; local.i <= ArrayLen(local.matches); local.i++) {
					local.match = local.matches[local.i];
					print.line("  - " & local.match.pattern & " -> " & local.match.controller & "##" & local.match.action);
				}
			}
			
		} catch (any e) {
			error("Error matching route: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				error("Details: " & e.detail);
			}
		}
	}

	private boolean function routeMatches(required struct route, required string url, required string method) {
		// Check method first
		local.routeMethods = arguments.route.methods ?: "GET";
		if (IsArray(local.routeMethods)) {
			if (!ArrayFindNoCase(local.routeMethods, arguments.method)) {
				return false;
			}
		} else {
			if (CompareNoCase(local.routeMethods, arguments.method) != 0 && local.routeMethods != "*") {
				return false;
			}
		}
		
		// Check pattern
		local.pattern = arguments.route.pattern ?: "";
		
		// Convert Wheels pattern to regex
		local.regex = local.pattern;
		// Replace [key] with numeric pattern
		local.regex = REReplaceNoCase(local.regex, "\[key\]", "(\d+)", "all");
		// Replace named parameters like :id with pattern
		local.regex = REReplaceNoCase(local.regex, ":(\w+)", "([\w-]+)", "all");
		// Escape special characters
		local.regex = REReplace(local.regex, "([\.\+\?\^\$\{\}\(\)\|\[\]\\])", "\\\1", "all");
		// Ensure exact match
		local.regex = "^" & local.regex & "$";
		
		// Test the match
		return REFindNoCase(local.regex, arguments.url) > 0;
	}

	private struct function extractParameters(required string pattern, required string url) {
		local.params = {};
		
		// Extract [key] parameters
		if (Find("[key]", arguments.pattern)) {
			local.keyPattern = Replace(arguments.pattern, "[key]", "(\d+)", "all");
			local.keyPattern = "^" & local.keyPattern & "$";
			local.matches = REMatchNoCase(local.keyPattern, arguments.url);
			if (ArrayLen(local.matches)) {
				local.keyValue = REReplace(arguments.url, local.keyPattern, "\1");
				if (IsNumeric(local.keyValue)) {
					local.params.key = local.keyValue;
				}
			}
		}
		
		// Extract named parameters like :id
		local.paramNames = REMatchNoCase(":(\w+)", arguments.pattern);
		if (ArrayLen(local.paramNames)) {
			local.regex = arguments.pattern;
			for (local.paramName in local.paramNames) {
				local.cleanName = Replace(local.paramName, ":", "");
				local.regex = Replace(local.regex, local.paramName, "([^/]+)");
			}
			local.regex = "^" & local.regex & "$";
			
			if (REFindNoCase(local.regex, arguments.url)) {
				// Extract values
				local.parts = REMatchNoCase(local.regex, arguments.url);
				// This is simplified - in reality would need more complex extraction
			}
		}
		
		return local.params;
	}

	private array function getRoutes(required string appPath) {
		local.routes = [];
		
		// Try to read routes from config/routes.cfm
		local.routesFile = arguments.appPath & "/config/routes.cfm";
		if (!FileExists(local.routesFile)) {
			return local.routes;
		}
		
		// Parse the routes file to extract route definitions
		local.routesContent = FileRead(local.routesFile);
		
		// Look for mapper method calls
		local.patterns = [
			// resource routes
			'resources\s*\(\s*["'']([\w]+)["'']',
			// named routes
			'(get|post|put|patch|delete)\s*\(\s*name\s*=\s*["'']([\w]+)["''],\s*pattern\s*=\s*["'']([^"'']+)["'']',
			// pattern routes
			'(get|post|put|patch|delete)\s*\(\s*["'']([^"'']+)["'']',
			// root route
			'root\s*\(\s*to\s*=\s*["'']([^##]+)##([^"'']+)["'']'
		];
		
		// Extract resource routes
		local.resourceMatches = REMatchNoCase(local.patterns[1], local.routesContent);
		for (local.match in local.resourceMatches) {
			local.resourceName = REReplace(local.match, local.patterns[1], "\1");
			
			// Add standard RESTful routes for resource
			local.routes.append({name: local.resourceName & "_index", methods: "GET", pattern: "/" & local.resourceName, controller: local.resourceName, action: "index"});
			local.routes.append({name: local.resourceName & "_new", methods: "GET", pattern: "/" & local.resourceName & "/new", controller: local.resourceName, action: "new"});
			local.routes.append({name: local.resourceName & "_create", methods: "POST", pattern: "/" & local.resourceName, controller: local.resourceName, action: "create"});
			local.routes.append({name: local.resourceName & "_show", methods: "GET", pattern: "/" & local.resourceName & "/[key]", controller: local.resourceName, action: "show"});
			local.routes.append({name: local.resourceName & "_edit", methods: "GET", pattern: "/" & local.resourceName & "/[key]/edit", controller: local.resourceName, action: "edit"});
			local.routes.append({name: local.resourceName & "_update", methods: ["PUT", "PATCH"], pattern: "/" & local.resourceName & "/[key]", controller: local.resourceName, action: "update"});
			local.routes.append({name: local.resourceName & "_delete", methods: "DELETE", pattern: "/" & local.resourceName & "/[key]", controller: local.resourceName, action: "delete"});
		}
		
		// Extract root route
		local.rootMatches = REMatchNoCase(local.patterns[4], local.routesContent);
		for (local.match in local.rootMatches) {
			local.controller = REReplace(local.match, local.patterns[4], "\1");
			local.action = REReplace(local.match, local.patterns[4], "\2");
			local.routes.append({name: "root", methods: "GET", pattern: "/", controller: local.controller, action: local.action});
		}
		
		// Note: Full route parsing would require executing the routes.cfm file
		// This is a simplified version that extracts common patterns
		
		return local.routes;
	}

}