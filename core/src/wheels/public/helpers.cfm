<cfscript>
/**
 * Page Header
 *
 * @title string
 * @subtitle string
 **/
function pageHeader(string title = "", string subTitle = "") {
	local.rv = '<h1 class="ui dividing header">';
	local.rv &= arguments.title;
	local.rv &= '<div class="sub header">';
	local.rv &= arguments.subtitle;
	local.rv &= '</div></h1>';
	return local.rv;
}
/**
 * Start table markup
 *
 * @title Name for header title
 * @colspan Colspan of header
 **/
function startTable(string title = "", colspan = 2) {
	local.rv = '<table class="ui celled striped table"><thead><tr><th colspan="';
	local.rv &= arguments.colspan;
	local.rv &= '">';
	local.rv &= arguments.title;
	local.rv &= '</th></tr></thead><tbody>';
	return local.rv;
}
/**
 * End table markup
 **/
function endTable() {
	return "</tbody></table>";
}
/**
 * Start tab markup
 *
 * @tab id of tab
 * @active whether active
 **/
function startTab(string tab = "", boolean active = false) {
	local.rv = '<div class="ui bottom attached tab segment';
	if (arguments.active) {
		local.rv &= ' active';
	}
	local.rv &= '" data-tab="';
	local.rv &= arguments.tab;
	local.rv &= '" style="overflow-x: auto;">';
	return local.rv;
}

/**
 * End tab markup
 **/
function endTab() {
	return '</div>';
}
/**
 * Determine CSS Class of http verb
 *
 * @verb http verb
 **/
function httpVerbClass(string verb) {
	switch (arguments.verb) {
		case "GET":
			return "green";
			break;
		case "POST":
			return "blue";
			break;
		case "PUT":
			return "violet";
			break;
		case "PATCH":
			return "purple";
			break;
		case "DELETE":
			return "red";
			break;
	}
}
/**
 * Markup for main environment setting output
 *
 * @setting array of settings with corresponding env vars
 **/
function outputSetting(array setting) {
	local.rv = "";
	for (var i = 1; i LTE ArrayLen(arguments.setting); i = i + 1) {
		local.rv &= '<tr><td class="four wide">';
		local.rv &= ReReplace(ReReplace(arguments.setting[i], "(^[a-z])", "\u\1"), "([A-Z])", " \1", "all");
		local.rv &= '</td><td class="eight wide">';
		local.rv &= formatSettingOutput(get(arguments.setting[i]));
		local.rv &= '</td></tr>';
	}
	return local.rv;
}
/**
 * Format any setting into something more pretty for output
 *
 * @val any type of value
 **/
function formatSettingOutput(any val) {
	local.rv = '';
	local.val = arguments.val;
	if (IsSimpleValue(local.val)) {
		if (IsBoolean(local.val)) {
			if (local.val) {
				local.rv = '<svg xmlns="http://www.w3.org/2000/svg" height="16" width="14" viewBox="0 0 448 512"><path d="M438.6 105.4c12.5 12.5 12.5 32.8 0 45.3l-256 256c-12.5 12.5-32.8 12.5-45.3 0l-128-128c-12.5-12.5-12.5-32.8 0-45.3s32.8-12.5 45.3 0L160 338.7 393.4 105.4c12.5-12.5 32.8-12.5 45.3 0z"/></svg>';
			} else {
				local.rv = '<svg xmlns="http://www.w3.org/2000/svg" height="10" width="10" viewBox="0 0 384 512"><path d="M376.6 84.5c11.3-13.6 9.5-33.8-4.1-45.1s-33.8-9.5-45.1 4.1L192 206 56.6 43.5C45.3 29.9 25.1 28.1 11.5 39.4S-3.9 70.9 7.4 84.5L150.3 256 7.4 427.5c-11.3 13.6-9.5 33.8 4.1 45.1s33.8 9.5 45.1-4.1L192 306 327.4 468.5c11.3 13.6 31.5 15.4 45.1 4.1s15.4-31.5 4.1-45.1L233.7 256 376.6 84.5z"/></svg>';
			}
		} else if (ListLen(local.val, ',') GT 4) {
			for (var item in local.val) {
				local.rv &= item & '<br>';
			}
		} else if (!Len(local.val)) {
			local.rv = '<em>Empty String</em>';
		} else {
			local.rv = arguments.val;
		}
	} else if (IsArray(local.val)) {
		for (var i = 1; i LTE ArrayLen(local.val); i = i + 1) {
			local.rv &= i & '->' & local.val[i] & '<br>';
		}
	} else if (IsStruct(local.val)) {
		for (var item in local.val) {
			local.rv &= item & '->' & local.val[item] & '<br>';
		}
	} else {
		local.rv = '<i class="icon question"></i>';
	}
	return local.rv;
}
/**
 * Return active route from nav
 *
 * @testFor name of route
 * @navigation array
 **/
function getActiveRoute(required string testFor, array navigation) {
	local.rv = {};
	for (local.n in arguments.navigation) {
		if (local.n.route == arguments.testFor) local.rv = local.n;
	}
	return local.rv;
}
/**
 * Output a route row
 **/
function outputRouteRow(struct route) {
	local.rv = "<tr>";
	local.rv &= "<td>" & route.name & "</td>";
	local.rv &= "<td><div class='ui " & httpVerbClass(EncodeForHTML(UCase(route.methods))) & " horizontal label'>" & route.methods & "</div></td>";
	local.rv &= "<td>" & route.pattern & "</td>";
	if (StructKeyExists(route, "redirect")) {
		local.rv &= "<td colspan='2'>" & truncate(EncodeForHTML(route.redirect), 70) & "</td>";
	} else {
		local.rv &= "<td>";
		if (StructKeyExists(route, "controller")) {
			local.rv &= route.controller;
		}
		local.rv &= "</td><td>";
		if (StructKeyExists(route, "action")) {
			local.rv &= route.action;
		}
		local.rv &= "</td>";
	}
	local.rv &= "</td></tr>";
	return local.rv;
}

/**
 * Altered Internal function for route tester
 */
public struct function $$findMatchingRoutes(
	string path = request.wheels.params.path,
	string requestMethod = request.wheels.params.verb
) {
	local.rv = {};
	local.matches = [];
	local.errors = [];

	// If this is a HEAD request, look for the corresponding GET route
	if (arguments.requestMethod == 'HEAD') {
		arguments.requestMethod = 'GET';
	}

	// Remove any query params
	if (arguments.path CONTAINS "?") arguments.path = ListFirst(arguments.path, "?");

	// Remove leading / if not '/'
	if (Left(arguments.path, 1) EQ "/" && arguments.path != "/")
		arguments.path = Right(arguments.path, (Len(arguments.path) - 1));

	// Loop over Wheels routes.
	for (local.route in application.wheels.routes) {
		if (StructKeyExists(local.route, "methods") && !ListFindNoCase(local.route.methods, arguments.requestMethod))
			continue;

		if (!StructKeyExists(local.route, "regex"))
			local.route.regex = application.wheels.mapper.$patternToRegex(local.route.pattern);

		if (ReFindNoCase(local.route.regex, arguments.path) || (!Len(arguments.path) && local.route.pattern == "/"))
			ArrayAppend(local.matches, local.route);
	}

	local.alternativeMatchingMethodsForURL = "";

	for (local.route in application.wheels.routes) {
		if (!StructKeyExists(local.route, "regex"))
			local.route.regex = application.wheels.mapper.$patternToRegex(local.route.pattern);

		if (ReFindNoCase(local.route.regex, arguments.path) || (!Len(arguments.path) && local.route.pattern == "/"))
			local.alternativeMatchingMethodsForURL = ListAppend(local.alternativeMatchingMethodsForURL, local.route.methods);
	}

	if (!ArrayLen(local.matches)) {
		if (Len(local.alternativeMatchingMethodsForURL)) {
			ArrayAppend(
				local.errors,
				{
					type = "Wheels.RouteNotFound",
					message = "Incorrect HTTP Verb for route",
					extendedInfo = "The `#arguments.path#` path does not allow `#EncodeForHTML(arguments.requestMethod)#` requests, only `#UCase(local.alternativeMatchingMethodsForURL)#` requests. Ensure you are using the correct HTTP Verb and that your `config/routes.cfm` file is configured correctly."
				}
			);
		} else {
			ArrayAppend(
				local.errors,
				{
					type = "Wheels.RouteNotFound - 404",
					message = "Could not find a route that matched this request",
					extendedInfo = "Make sure there is a route configured in your `config/routes.cfm` file that matches the `#EncodeForHTML(arguments.path)#` request."
				}
			);
		}
	}

	local.rv["matches"] = local.matches;
	local.rv["errors"] = local.errors;
	return local.rv;
}

function $$getAllDatabaseInformation() {
	local.info = $dbinfo(
		type = "version",
		datasource = application.wheels.dataSourceName,
		username = application.wheels.dataSourceUserName,
		password = application.wheels.dataSourcePassword
	);
	local.adapterName = "";
	if (
		local.info.driver_name Contains "SQLServer" || local.info.driver_name Contains "Microsoft SQL Server" || local.info.driver_name Contains "MS SQL Server" || local.info.database_productname Contains "Microsoft SQL Server"
	) {
		local.adapterName = "MicrosoftSQLServer";
	} else if (local.info.driver_name Contains "MySQL") {
		local.adapterName = "MySQL";
	} else if (local.info.driver_name Contains "PostgreSQL") {
		local.adapterName = "PostgreSQL";
		// NB: using mySQL adapter for H2 as the cli defaults to this for development
	} else if (local.info.driver_name Contains "H2") {
		// determine the emulation mode
		/*
	if (StructKeyExists(server, "lucee")) {
		local.connectionString = GetApplicationMetaData().datasources[application[local.appKey].dataSourceName].connectionString;
	} else {
		// TODO: use the coldfusion class to dig out dsn info
		local.connectionString = "";
	}
	if (local.connectionString Contains "mode=SQLServer" || local.connectionString Contains "mode=Microsoft SQL Server" || local.connectionString Contains "mode=MS SQL Server" || local.connectionString Contains "mode=Microsoft SQL Server") {
		local.adapterName = "MicrosoftSQLServer";
	} else if (local.connectionString Contains "mode=MySQL") {
		local.adapterName = "MySQL";
	} else if (local.connectionString Contains "mode=PostgreSQL") {
		local.adapterName = "PostgreSQL";
	} else {
		local.adapterName = "MySQL";
	}
	*/
		local.adapterName = "H2";
	} else if (local.info.driver_name Contains "Oracle") {
		local.adapterName = "Oracle";
	} else if (local.info.driver_name Contains "SQLite") {
		local.adapterName = "SQLite";
	}
	return local;
}
/**
 * Return the main documentation struct with an array of sections, and an array of functions
 */
struct function $returnInternalDocumentation(required array documentScope, required array ignore) {
	local.rv["functions"] = $populateDocFunctionMeta(documentScope, ignore);
	local.rv["sections"] = $populateDocSections(local.rv.functions);

	// Look for [see:something] tags to pull in other function param hints
	for (local.i = 1; i LTE ArrayLen(local.rv["functions"]); i = i + 1) {
		if (StructKeyExists(local.rv["functions"][i], "parameters")) {
			for (local.p = 1; p LTE ArrayLen(local.rv["functions"][i]["parameters"]); p = p + 1) {
				if (StructKeyExists(local.rv["functions"][i]["parameters"][p], "hint")) {
					local.rv["functions"][i]["parameters"][p]["hint"] = $replaceSeeTag(
						local.rv["functions"][i]["parameters"][p]["hint"],
						local.rv["functions"][i]["parameters"][p]["name"],
						local.rv["functions"]
					);
				}
			}
		}
	}
	return local.rv;
}

/**
 * Directly replace a see tag i.e [see:findAll] with it's param equivalent in the other function
 * NB, this is actually a catch 22 as the params for other functions might not yet have been parsed
 * So we do this as a separate loop at the end.
 *
 * @string String containing [see:otherFunctionName]
 * @name the param name to get from the other function
 * @allfunctions the existing document struct
 **/
string function $replaceSeeTag(required string string, required string name, required array allfunctions) {
	local.rv = arguments.string;
	local.name = arguments.name;
	local.tags = ReMatchNoCase('\[((see?):(.*?))\]', local.rv);
	if (ArrayLen(local.tags)) {
		for (local.tag in local.tags) {
			// Get the contents of see:"Foo"
			var lookUpfunctionName = Replace(ListLast(local.tag, ":"), "]", "", "one");
			// Look for that function in the main function struct
			local.match = ArrayFind(arguments.allfunctions, function(struct) {
				return (struct.name == lookUpfunctionName);
			});
			if (local.match) {
				local.matchedParam = ArrayFind(arguments.allfunctions[local.match]["parameters"], function(struct) {
					return (struct.name == name);
				});
				if (
					local.matchedParam && StructKeyExists(
						arguments.allfunctions[local.match]["parameters"][local.matchedParam],
						"hint"
					)
				) {
					local.rv = arguments.allfunctions[local.match]["parameters"][local.matchedParam]["hint"];
				}
			}
		}
	}
	return local.rv;
}

/**
 * For each type of cfc, i.e, model, controller, mapper, loop over the available functions and populate the
 * function's metadata via getMetaData()
 *
 * @documentScope The Array of structs containing CFCs to introspect
 * @ignore an array of function names to ignore. config() and init() are the usual ones.
 */
array function $populateDocFunctionMeta(required array documentScope, required array ignore) {
	local.rv = [];
	for (local.doctype in arguments.documentScope) {
		local.doctype["functions"] = ListSort(StructKeyList(local.doctype.scope), "textnocase");
		// Populate A-Z function List
		for (local.functionName in ListToArray(local.doctype.functions)) {
			local.meta = {};
			local.hint = "";
			// Check this is actually a function: migrator stores a struct for instance
			// Don't display internal functions, duplicates or anything in the ignore list
			if (
				Left(local.functionName, 1) != "$"
				&& !ArrayFindNoCase(arguments.ignore, local.functionName)
				&& IsCustomFunction(local.doctype.scope[local.functionName])
			) {
				// Get metadata
				local.meta = $parseMetaData(
					GetMetadata(local.doctype.scope[local.functionName]),
					local.doctype.name,
					local.functionName
				);
				local.hint = local.meta.hint;

				if (local.meta.name != "$pluginRunner") {
					// Look for identically named functions: just looking for name isn't enough, we need to compare the hint too
					local.match = ArrayFind(local.rv, function(struct) {
						return (struct.name == functionName && struct.hint == hint);
					});

					if (local.match) {
						ArrayAppend(local.rv[local.match]["availableIn"], local.doctype.name);
					} else {
						ArrayAppend(local.rv, local.meta);
					}
				}
			}
		}
		local.rv = $arrayOfStructsSort(local.rv, "name");
	}
	return local.rv;
}

/**
 * Look for [section:foo] style categories and build the categories array
 *
 * @docFunctions an array of function meta data as created by $populateDocFunctionMeta
 */
array function $populateDocSections(required array docFunctions) {
	local.rv = [];
	local.distinctSections = [];
	for (local.doc in arguments.docFunctions) {
		if (StructKeyExists(local.doc.tags, "section") && Len(local.doc.tags.section)) {
			if (!ArrayFindNoCase(local.distinctSections, local.doc.tags.section)) {
				ArrayAppend(local.rv, {"name" = local.doc.tags.section, "categories" = []});
				ArrayAppend(local.distinctSections, local.doc.tags.section);
			}
			for (local.subsection in local.rv) {
				if (
					local.subsection.name == local.doc.tags.section
					&& Len(local.doc.tags.category)
					&& !ArrayFindNoCase(local.subsection.categories, local.doc.tags.category)
				) {
					ArrayAppend(local.subsection.categories, local.doc.tags.category);
				}
				ArraySort(local.subsection.categories, "textnocase");
			}
		}
	}
	local.rv = $arrayOfStructsSort(local.rv, "name");
	return local.rv;
}

/**
 * Take a metadata struct as from getMetaData() and get some additional info
 *
 * @meta metadata struct as returned from getMetaData()
 * @doctype ie. Controller || Model
 */
struct function $parseMetaData(required struct meta, required string doctype, required string functionName) {
	local.m = arguments.meta;
	local.rv["name"] = StructKeyExists(local.m, "name") ? local.m.name : "";
	local.rv["availableIn"] = [doctype];
	local.rv["slug"] = $createFunctionSlug(doctype, local.rv.name);
	local.rv["parameters"] = StructKeyExists(local.m, "parameters") ? local.m.parameters : [];
	local.rv["returntype"] = StructKeyExists(local.m, "returntype") ? local.m.returntype : "";
	local.rv["hint"] = StructKeyExists(local.m, "hint") ? local.m.hint : "";
	local.rv["tags"] = {};

	// Look for [something: Foo] style tags in hint
	if (StructKeyExists(local.rv, "hint")) {
		local.rv.tags["section"] = $getDocTag(local.rv.hint, "section");
		local.rv.tags["sectionClass"] = $cssClassLink(local.rv.tags.section);
		local.rv.tags["category"] = $getDocTag(local.rv.hint, "category");
		local.rv.tags["categoryClass"] = $cssClassLink(local.rv.tags.category);
		local.rv.hint = $replaceDocLink(local.rv.hint);
		local.rv.hint = $stripDocTags(local.rv.hint);
		local.rv.hint = $backTickReplace(local.rv.hint);
	}

	// Parse Params
	for (param in local.rv["parameters"]) {
		// Check for param defaults within wheels settings
		if (
			StructKeyExists(application.wheels.functions, local.rv.name)
			&& StructKeyExists(application.wheels.functions[local.rv.name], param.name)
		) {
			param['default'] = application.wheels.functions[local.rv.name][param.name];
		}

		if (StructKeyExists(param, "hint")) {
			// Parse any other [doc:something tags]
			param['hint'] = $replaceDocLink(param.hint);
		}
	}
	// Check for extended documentation: note this is not looked for by slug, i.e. controller/humanize.txt
	local.rv["extended"] = $getExtendedCodeExamples("wheels/public/docs/reference/", local.rv.slug);
	return local.rv;
}

/**
 * Creates a function slug
 */
string function $createFunctionSlug(required string doctype, required string functionName) {
	return doctype & '.' & functionName;
}

/**
 * Retrieve a [tag: foo] style tag
 * Returns a comma delim list of matches
 *
 * @string String to search
 * @tagname Tag to find
 **/
string function $getDocTag(required string string, required string tagname) {
	local.rv = "";
	local.string = arguments.string;
	local.tagname = arguments.tagname;
	local.tags = ReMatchNoCase('\[((' & local.tagname & '?):(.*?))\]', local.string);
	if (ArrayLen(local.tags)) {
		for (local.tag in local.tags) {
			local.rv = ListAppend(local.rv, Trim(Replace(ListLast(local.tag, ":"), "]", "", "one")));
		}
	}
	return local.rv;
}

/**
 * Directly replace a doc tag i.e format [doc:functionName] to a hashLink
 *
 * @string String to search
 **/
string function $replaceDocLink(required string string) {
	local.rv = arguments.string;
	local.tags = ReMatchNoCase('\[((doc?):(.*?))\]', local.rv);
	if (ArrayLen(local.tags)) {
		for (local.tag in local.tags) {
			local.link = Replace(ListLast(local.tag, ":"), "]", "", "one");
			local.rv = ReplaceNoCase(local.rv, local.tag, "<a href='##" & LCase(local.link) & "'>" & local.link & "</a>");
		}
	}
	return local.rv;
}
/**
 * Strip [tag: foo] style tags
 *
 * @string String to search
 **/
string function $stripDocTags(required string string) {
	return ReReplaceNoCase(arguments.string, "\[((.*?):(.*?))\]", "", "ALL");
}


/**
 * Check for Extended Docs
 *
 * @pathToExtended The Path to the Extended doc txt files
 * @functionName The Function Name
 */
struct function $getExtendedCodeExamples(pathToExtended, slug) {
	local.rv = {};
	local.rv["path"] = ExpandPath(pathToExtended) & LCase(Replace(slug, ".", "/", "one")) & ".txt";
	local.rv["hasExtended"] = FileExists(local.rv.path) ? true : false;
	local.rv["docs"] = "";
	if (local.rv.hasExtended) {
		local.rv["docs"] = "<pre><code class='javascript'>" & HtmlEditFormat(FileRead(local.rv.path)) & "</code></pre>";
		local.rv["docs"] = Trim(local.rv["docs"]);
	}
	StructDelete(local.rv, "path");
	return local.rv;
}

/**
 * Formats the Main Hint
 *
 * @str The Hint String
 */
string function $hintOutput(str) {
	local.rv = $backTickReplace(arguments.str);
	return Trim(local.rv);
	// return simpleFormat(text=trim(local.rv), encode=false);
}

/**
 * Searches for ``` in hint description output and formats
 *
 * @str The String to search
 */
string function $backTickReplace(str) {
	return ReReplaceNoCase(arguments.str, '`(.*?)`', '<code>\1</code>', "ALL");
}
/**
 * Turns "My Thing" into "mything"
 *
 * @str The String
 */
string function $cssClassLink(str) {
	return Trim(Replace(LCase(str), " ", "", "all"));
}

/**
 * Sorts an array of structures based on a key in the structures.
 *
 * @param aofS      Array of structures.
 * @param key      Key to sort by.
 * @param sortOrder      Order to sort by, asc or desc.
 * @param sortType      Text, textnocase, or numeric.
 * @param delim      Delimiter used for temporary data storage. Must not exist in data. Defaults to a period.
 * @return Returns a sorted array.
 * @author Nathan Dintenfass (nathan@changemedia.com)
 * @version 1, December 10, 2001
 */
function $arrayOfStructsSort(aOfS, key) {
	// by default we'll use an ascending sort
	var sortOrder = "asc";
	// by default, we'll use a textnocase sort
	var sortType = "textnocase";
	// by default, use ascii character 30 as the delim
	var delim = ".";
	// make an array to hold the sort stuff
	var sortArray = ArrayNew(1);
	// make an array to return
	var returnArray = ArrayNew(1);
	// grab the number of elements in the array (used in the loops)
	var count = ArrayLen(aOfS);
	// make a variable to use in the loop
	var ii = 1;
	// if there is a 3rd argument, set the sortOrder
	if (ArrayLen(arguments) GT 2) sortOrder = arguments[3];
	// if there is a 4th argument, set the sortType
	if (ArrayLen(arguments) GT 3) sortType = arguments[4];
	// if there is a 5th argument, set the delim
	if (ArrayLen(arguments) GT 4) delim = arguments[5];
	// loop over the array of structs, building the sortArray
	for (ii = 1; ii lte count; ii = ii + 1) sortArray[ii] = aOfS[ii][key] & delim & ii;
	// now sort the array
	ArraySort(sortArray, sortType, sortOrder);
	// now build the return array
	for (ii = 1; ii lte count; ii = ii + 1) returnArray[ii] = aOfS[ListLast(sortArray[ii], delim)];
	// return the array
	return returnArray;
}
</cfscript>
