component {
	/**
	 * Create a group of routes that exposes actions for manipulating a singular resource. A singular resource exposes URL patterns for the entire CRUD lifecycle of a single entity (`show`, `new`, `create`, `edit`, `update`, and `delete`) without exposing a primary key in the URL. Usually this type of resource represents a singleton entity tied to the session, application, or another resource (perhaps nested within another resource). If you need to generate routes for manipulating a collection of resources with a primary key in the URL, see the `resources` mapper method.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @name Camel-case name of resource to reference when build links and form actions. This is typically a singular word (e.g., `profile`).
	 * @nested Whether or not additional calls will be nested within this resource.
	 * @path Override URL path representing this resource. Default is a dasherized version of `name` (e.g., `blogPost` generates a path of `blog-post`).
	 * @controller Override name of the controller used by resource. This defaults to a pluralized version of `name`.
	 * @singular Override singularize() result in plural resources.
	 * @plural Override pluralize() result in singular resource.
	 * @only Limits the list of RESTful routes to generate. Can include `show`, `new`, `create`, `edit`, `update`, and `delete`.
	 * @except Excludes RESTful routes to generate, taking priority over the `only` argument. Can include `show`, `new`, `create`, `edit,` `update`, and `delete`.
	 * @shallow Turn on shallow resources.
	 * @shallowPath Shallow path prefix.
	 * @shallowName Shallow name prefix.
	 * @constraints Variable patterns to use for matching.
	 * @mapFormat Whether or not to add an optional `.[format]` pattern to the end of the generated routes. This is useful for providing formats via URL like `json`, `xml`, `pdf`, etc.
	 */
	public struct function resource(
		required string name,
		boolean nested = false,
		string path = hyphenize(arguments.name),
		string controller,
		string singular,
		string plural,
		string only,
		string except,
		boolean shallow,
		string shallowPath,
		string shallowName,
		struct constraints,
		string $call = "resource",
		boolean $plural = false,
		boolean mapFormat = variables.mapFormat
	) {
		local.args = {};

		// If name is a list, add each of the resources in the list.
		if (Find(",", arguments.name)) {
			// Error if the user asked for a nested resource.
			if (arguments.nested) {
				Throw(type = "Wheels.InvalidResource", message = "Multiple resources in same declaration cannot be nested.");
			}

			// Remove path so new resources do not break.
			StructDelete(arguments, "path");

			// Build each new resource.
			local.names = ListToArray(arguments.name);
			local.iEnd = ArrayLen(local.names);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				resource(name = local.names[local.i], argumentCollection = arguments);
			}
			return this;
		}

		if (arguments.$plural) {
			// Setup singular and plural words.
			if (!StructKeyExists(arguments, "singular")) {
				arguments.singular = singularize(arguments.name);
			}
			arguments.plural = arguments.name;

			// Set collection and scoped paths.
			local.args.collection = arguments.plural;
			local.args.nestedPath = "#arguments.path#/[#arguments.singular#Key]";
			local.args.memberPath = "#arguments.path#/[key]";

			// For uncountable plurals, append "Index".
			if (arguments.singular == arguments.plural) {
				local.args.collection &= "Index";
			}

			local.args.actions = "index,new,create,show,edit,update,delete";
		} else {
			// Setup singular and plural words.
			arguments.singular = arguments.name;
			if (!StructKeyExists(arguments, "plural")) {
				arguments.plural = pluralize(arguments.name);
			}

			// Set collection and scoped paths.
			local.args.collection = arguments.singular;
			local.args.memberPath = arguments.path;
			local.args.nestedPath = arguments.path;

			local.args.actions = "new,create,show,edit,update,delete";
		}
		local.args.member = arguments.singular;
		local.args.collectionPath = arguments.path;

		// Consider only / except REST routes for resources.
		// Allow arguments.only to override local.args.only.
		if (StructKeyExists(arguments, "only")) {
			local.args.actions = LCase(arguments.only);
		}

		// Remove unwanted routes from local.args.only.
		if (StructKeyExists(arguments, "except") && ListLen(arguments.except) > 0) {
			local.except = ListToArray(arguments.except);
			local.iEnd = ArrayLen(local.except);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.args.actions = ReReplace(local.args.actions, "\b#local.except[local.i]#\b(,?|$)", "");
			}
		}

		// If controller name was passed, use it.
		// Else, set controller name based on naming preference
		if (StructKeyExists(arguments, "controller")) {
			local.args.controller = arguments.controller;
		} else {
			switch (variables.resourceControllerNaming) {
				case "name":
					local.args.controller = arguments.name;
					break;
				case "singular":
					local.args.controller = arguments.singular;
					break;
				default:
					local.args.controller = arguments.plural;
			}
		}

		// If parent resource is found.
		if (StructKeyExists(variables.scopeStack[1], "member")) {
			// Use member and nested path.
			local.args.name = variables.scopeStack[1].member;
			local.args.path = variables.scopeStack[1].nestedPath;

			// Store parent resource (and avoid too deep nesting).
			local.args.parentResource = Duplicate(variables.scopeStack[1]);
			if (StructKeyExists(local.args.parentResource, "parentResource")) {
				StructDelete(local.args.parentResource, "parentResource");
			}
		}

		// Pass along shallow route options.
		if (StructKeyExists(arguments, "shallow")) {
			local.args.shallow = arguments.shallow;
		}
		if (StructKeyExists(arguments, "shallowPath")) {
			local.args.shallowPath = arguments.shallowPath;
		}
		if (StructKeyExists(arguments, "shallowName")) {
			local.args.shallowName = arguments.shallowName;
		}

		// Pass along constraints.
		if (StructKeyExists(arguments, "constraints")) {
			local.args.constraints = arguments.constraints;
		}

		// Pass along mapFormat preference
		if (StructKeyExists(arguments, "mapFormat")) {
			local.args.mapFormat = arguments.mapFormat;
		}

		// Scope the resource.
		scope($call = arguments.$call, argumentCollection = local.args);

		// Call end() automatically unless this is a nested call.
		// See 'end()' source for the resource routes logic.
		if (!arguments.nested) {
			end();
		}

		return this;
	}

	/**
	 * Create a group of routes that exposes actions for manipulating a collection of resources. A plural resource exposes URL patterns for the entire CRUD lifecycle (`index`, `show`, `new`, `create`, `edit`, `update`, `delete`), exposing a primary key in the URL for showing, editing, updating, and deleting records. If you need to generate routes for manipulating a singular resource without a primary key, see the `resource` mapper method.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @name Camel-case name of resource to reference when build links and form actions. This is typically a plural word (e.g., `posts`).
	 * @nested Whether or not additional calls will be nested within this resource.
	 * @path Override URL path representing this resource. Default is a dasherized version of `name` (e.g., `blogPosts` generates a path of `blog-posts`).
	 * @controller Override name of the controller used by resource. This defaults to the value provided for `name`.
	 * @singular Override singularize() result in plural resources.
	 * @plural Override pluralize() result in singular resource.
	 * @only Limits the list of RESTful routes to generate. Can include `index`, `show`, `new`, `create`, `edit`, `update`, and `delete`.
	 * @except Excludes RESTful routes to generate, taking priority over the `only` argument. Can include `index`, `show`, `new`, `create`, `edit`, `update`, and `delete`.
	 * @shallow Turn on shallow resources.
	 * @shallowPath Shallow path prefix.
	 * @shallowName Shallow name prefix.
	 * @constraints Variable patterns to use for matching.
	 * @mapFormat Whether or not to add an optional `.[format]` pattern to the end of the generated routes. This is useful for providing formats via URL like `json`, `xml`, `pdf`, etc.
	 */
	public struct function resources(
		required string name,
		boolean nested = false,
		string path = hyphenize(arguments.name),
		string controller,
		string singular,
		string plural,
		string only,
		string except,
		boolean shallow,
		string shallowPath,
		string shallowName,
		struct constraints,
		boolean mapFormat = variables.mapFormat
	) {
		return resource(argumentCollection = arguments, $plural = true, $call = "resources");
	}

	/**
	 * Scope routes within a nested resource which require use of the primary key as part of the URL pattern;
	 * A member route will require an ID, because it acts on a member.
	 * photos/1/preview is an example of a member route, because it acts on (and displays) a single object.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 */
	public struct function member() {
		return scope(path = variables.scopeStack[1].memberPath, $call = "member");
	}

	/**
	 * A collection route doesn't require an id because it acts on a collection of objects.
	 * photos/search is an example of a collection route, because it acts on (and displays) a collection of objects.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 */
	public struct function collection() {
		return scope(path = variables.scopeStack[1].collectionPath, $call = "collection");
	}
}
