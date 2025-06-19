/**
 * Display application routes
 *
 * {code:bash}
 * wheels routes
 * wheels routes name=users
 * wheels routes format=json
 * wheels routes name=users format=json
 * {code}
 */
component extends="base" {

	/**
	 * @name Filter routes by name
	 * @format Output format (table or json)
	 * @help Display all defined routes in the application
	 */
	public void function run(string name = "", string format = "table") {
		local.appPath = getCWD();
		
		if (!isWheelsApp(local.appPath)) {
			error("This command must be run from a Wheels application directory");
			return;
		}

		// Get the routes from the application
		try {
			local.routes = getRoutes(local.appPath);
			
			if (ArrayLen(local.routes) == 0) {
				print.yellowLine("No routes found in the application");
				return;
			}
			
			// Filter by name if provided
			if (Len(arguments.name)) {
				local.filteredRoutes = [];
				for (local.route in local.routes) {
					if (FindNoCase(arguments.name, local.route.name ?: "") || 
					    FindNoCase(arguments.name, local.route.pattern ?: "")) {
						ArrayAppend(local.filteredRoutes, local.route);
					}
				}
				local.routes = local.filteredRoutes;
			}
			
			if (ArrayLen(local.routes) == 0) {
				print.yellowLine("No routes found matching '#arguments.name#'");
				return;
			}
			
			// Output based on format
			if (arguments.format == "json") {
				print.line(SerializeJSON(local.routes));
			} else {
				// Display routes in a table
				print.line();
				print.boldLine("Application Routes:");
				print.line();
				
				// Calculate column widths
				local.nameWidth = 20;
				local.methodWidth = 10;
				local.patternWidth = 30;
				local.controllerWidth = 20;
				local.actionWidth = 15;
				
				// Header
				print.text(PadRight("Name", local.nameWidth));
				print.text(PadRight("Method", local.methodWidth));
				print.text(PadRight("Pattern", local.patternWidth));
				print.text(PadRight("Controller", local.controllerWidth));
				print.line(PadRight("Action", local.actionWidth));
				
				print.line(RepeatString("-", local.nameWidth + local.methodWidth + local.patternWidth + local.controllerWidth + local.actionWidth));
				
				// Routes
				for (local.route in local.routes) {
					local.name = local.route.name ?: "";
					local.methods = local.route.methods ?: "GET";
					local.pattern = local.route.pattern ?: "";
					local.controller = local.route.controller ?: "";
					local.action = local.route.action ?: "";
					
					// Handle multiple methods
					if (IsArray(local.methods)) {
						local.methods = ArrayToList(local.methods, ",");
					}
					
					print.text(PadRight(Left(local.name, local.nameWidth - 1), local.nameWidth));
					print.text(PadRight(Left(local.methods, local.methodWidth - 1), local.methodWidth));
					print.text(PadRight(Left(local.pattern, local.patternWidth - 1), local.patternWidth));
					print.text(PadRight(Left(local.controller, local.controllerWidth - 1), local.controllerWidth));
					print.line(PadRight(Left(local.action, local.actionWidth - 1), local.actionWidth));
				}
				
				print.line();
				print.greenLine("Total routes: " & ArrayLen(local.routes));
			}
			
		} catch (any e) {
			error("Error reading routes: " & e.message);
			if (StructKeyExists(e, "detail") && Len(e.detail)) {
				error("Details: " & e.detail);
			}
		}
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

	private string function PadRight(required string text, required numeric width) {
		if (Len(arguments.text) >= arguments.width) {
			return arguments.text;
		}
		return arguments.text & RepeatString(" ", arguments.width - Len(arguments.text));
	}

}