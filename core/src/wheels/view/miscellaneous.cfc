component {
	/**
	 * Highlights the phrase(s) everywhere in the text if found by wrapping them in `span` tags.
	 *
	 * [section: View Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @text Text to search in.
	 * @phrase Phrase (or list of phrases) to highlight. This argument is also aliased as `phrases`.
	 * @delimiter Delimiter to use when passing in multiple phrases.
	 * @tag HTML tag to use to wrap the highlighted phrase(s).
	 * @class Class to use in the tags wrapping highlighted phrase(s).
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function highlight(
		required string text,
		string phrase,
		string delimiter,
		string tag,
		string class,
		boolean encode
	) {
		$args(name = "highlight", args = arguments, combine = "phrase/phrases", required = "phrase");
		local.text = arguments.encode && $get("encodeHtmlTags") ? EncodeForHTML($canonicalize(arguments.text)) : arguments.text;

		// Return the passed in text unchanged (but encoded) if it's blank or the passed in phrase is blank.
		if (!Len(local.text) || !Len(arguments.phrase)) {
			return local.text;
		}

		local.phraseArray = ListToArray(arguments.phrase, arguments.delimiter);
		local.iEnd = ArrayLen(local.phraseArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.newText = "";
			local.phrase = Trim(local.phraseArray[local.i]);
			local.pos = 1;
			while (FindNoCase(local.phrase, local.text, local.pos)) {
				local.foundAt = FindNoCase(local.phrase, local.text, local.pos);
				local.previousText = Mid(local.text, local.pos, local.foundAt - local.pos);
				local.newText &= local.previousText;
				local.mid = Mid(local.text, local.foundAt, Len(local.phrase));
				local.startBracket = Find("<", local.text, local.foundAt);
				local.endBracket = Find(">", local.text, local.foundAt);
				if (local.startBracket < local.endBracket || !local.endBracket) {
					local.attributes = {class = arguments.class};
					local.newText &= $element(
						name = arguments.tag,
						content = local.mid,
						attributes = local.attributes,
						encode = arguments.encode
					);
				} else {
					local.newText &= local.mid;
				}
				local.pos = local.foundAt + Len(local.phrase);
			}
			local.newText &= Mid(local.text, local.pos, Len(local.text) - local.pos + 1);
			local.text = local.newText;
		}
		local.rv = local.newText;
		return local.rv;
	}

	/**
	 * Returns formatted text using HTML break tags (`<br>`) and HTML paragraph elements (`<p></p>`) based on the newline characters and carriage returns in the `text` that is passed in.
	 *
	 * [section: View Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @text The text to format.
	 * @wrap Set to `true` to wrap the result in a paragraph HTML element.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function simpleFormat(required string text, boolean wrap, boolean encode) {
		$args(name = "simpleFormat", args = arguments);
		local.rv = Trim(arguments.text);

		// Encode for html if specified, but revert the encoding of newline characters and carriage returns.
		// We can safely revert that part of the encoding since we'll replace them with html tags anyway.
		if (arguments.encode && $get("encodeHtmlTags")) {
			local.rv = EncodeForHTML($canonicalize(local.rv));
			local.rv = Replace(local.rv, "&##xa;", Chr(10), "all");
			local.rv = Replace(local.rv, "&##xd;", Chr(13), "all");
		}

		local.rv = Replace(local.rv, Chr(13), "", "all");
		local.rv = Replace(local.rv, Chr(10) & Chr(10), "</p><p>", "all");
		local.rv = Replace(local.rv, Chr(10), "<br>", "all");

		// Put the newline characters back in (good for editing in textareas with the original formatting for example).
		local.rv = Replace(local.rv, "</p><p>", "</p>" & Chr(10) & Chr(10) & "<p>", "all");
		local.rv = Replace(local.rv, "<br>", "<br>" & Chr(10), "all");

		if (arguments.wrap) {
			local.rv = "<p>" & local.rv & "</p>";
		}
		return local.rv;
	}

	/**
	 * Displays a marked-up listing of messages that exist in the Flash.
	 *
	 * [section: View Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @keys The key (or list of keys) to show the value for. You can also use the `key` argument instead for better readability when accessing a single key.
	 * @class HTML `class` to set on the `div` element that contains the messages.
	 * @includeEmptyContainer Includes the `div` container even if the Flash is empty.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function flashMessages(string keys, string class, boolean includeEmptyContainer, boolean encode) {
		$args(name = "flashMessages", args = arguments, combine = "keys/key");
		local.flash = $readFlash();
		local.rv = "";

		// if no keys are requested, populate with everything stored in the Flash and sort them
		if (!StructKeyExists(arguments, "keys")) {
			local.flashKeys = StructKeyList(local.flash);
			local.flashKeys = ListSort(local.flashKeys, "textnocase");
		} else {
			// otherwise, generate list based on what was passed as "arguments.keys"
			local.flashKeys = arguments.keys;
		}

		// generate markup for each Flash item in the list
		local.listItems = "";
		local.flashKeysArray = ListToArray(local.flashKeys);
		local.iEnd = ArrayLen(local.flashKeysArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = local.flashKeysArray[local.i];
			local.class = LCase(local.item) & "-message";
			local.attributes = {class = local.class};
			if (!StructKeyExists(arguments, "key") || arguments.key == local.item) {
				local.content = local.flash[local.item];
				// Do we have an array of values or a simple value?
				if (IsArray(local.content)) {
					for (local.contentItem in local.content) {
						local.listItems &= $element(
							name = "p",
							content = local.contentItem,
							attributes = local.attributes,
							encode = arguments.encode
						);
					}
				} else if (IsSimpleValue(local.content)) {
					local.listItems &= $element(
						name = "p",
						content = local.content,
						attributes = local.attributes,
						encode = arguments.encode
					);
				}
			}
		}

		if (Len(local.listItems) || arguments.includeEmptyContainer) {
			local.encode = arguments.encode ? "attributes" : false;
			local.rv = $element(
				name = "div",
				skip = "key,keys,includeEmptyContainer,encode",
				content = local.listItems,
				attributes = arguments,
				encode = local.encode
			);
		}
		return local.rv;
	}

	/**
	 * Used to store a section's output for rendering within a layout.
	 * This content store acts as a stack, so you can store multiple pieces of content for a given section.
	 *
	 * [section: View Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @position The position in the section's stack where you want the content placed. Valid values are `first`, `last`, or the numeric position.
	 * @overwrite Whether or not to overwrite any of the content. Valid values are `false`, `true`, or `all`.
	 */
	public void function contentFor(any position = "last", any overwrite = "false") {
		// position in the array for the content
		local.position = "last";

		// should we overwrite or insert into the array
		local.overwrite = "false";

		// extract optional arguments
		if (StructKeyExists(arguments, "position")) {
			local.position = arguments.position;
			StructDelete(arguments, "position");
		}
		if (StructKeyExists(arguments, "overwrite")) {
			local.overwrite = arguments.overwrite;
			StructDelete(arguments, "overwrite");
		}

		// if no other arguments exists, exit
		if (StructIsEmpty(arguments)) {
			return;
		}

		// since we're not going to know the name of the section, we have to get it dynamically
		local.section = ListFirst(StructKeyList(arguments));
		local.content = arguments[local.section];

		if (!IsBoolean(local.overwrite)) {
			local.overwrite = "all";
		}

		if (!StructKeyExists(variables.$instance.contentFor, local.section) || local.overwrite == "all") {
			// if the section doesn't exists, or they want to overwrite the whole thing
			variables.$instance.contentFor[local.section] = [];
			ArrayAppend(variables.$instance.contentFor[local.section], local.content);
		} else {
			local.size = ArrayLen(variables.$instance.contentFor[local.section]);
			// they want to append, prepend or insert at a specific point in the array
			// make sure position is within range
			if (!IsNumeric(local.position) && !ListFindNoCase("first,last", local.position)) {
				local.position = "last";
			}
			if (IsNumeric(local.position)) {
				if (local.position <= 1) {
					local.position = "first";
				} else if (local.position >= local.size) {
					local.position = "last";
				}
			}
			if (local.overwrite) {
				if (local.position == "last") {
					local.position = local.size;
				} else if (local.position == "first") {
					local.position = 1;
				}
				variables.$instance.contentFor[local.section][local.position] = local.content;
			} else {
				if (local.position == "last") {
					ArrayAppend(variables.$instance.contentFor[local.section], local.content);
				} else if (local.position == "first") {
					ArrayPrepend(variables.$instance.contentFor[local.section], local.content);
				} else {
					ArrayInsertAt(variables.$instance.contentFor[local.section], local.position, local.content);
				}
			}
		}
	}

	/**
	 * Includes the contents of another layout file.
	 * This is usually used to include a parent layout from within a child layout.
	 *
	 * [section: View Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @name Name of the layout file to include.
	 */
	public string function includeLayout(string name = "layout") {
		arguments.partial = arguments.name;
		StructDelete(arguments, "name");
		arguments.$prependWithUnderscore = false;
		return includePartial(argumentCollection = arguments);
	}

	/**
	 * Includes the specified partial file in the view.
	 * Similar to using `cfinclude` but with the ability to cache the result and use Wheels-specific file look-up.
	 * By default, Wheels will look for the file in the current controller's view folder.
	 * To include a file relative from the base `views` folder, you can start the path supplied to `partial` with a forward slash.
	 *
	 * [section: View Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @partial The name of the partial file to be used. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Do not include the partial filename's underscore and file extension. If you want to have Wheels display the partial for a single model object, array of model objects, or a query, pass a variable containing that data into this argument.
	 * @group If passing a query result set for the partial argument, use this to specify the field to group the query by. A new query will be passed into the partial template for you to iterate over.
	 * @cache Number of minutes to cache the content for.
	 * @layout The layout to wrap the content in. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Pass `false` to not load a layout at all.
	 * @spacer HTML or string to place between partials when called using a query.
	 * @dataFunction Name of controller function to load data from.
	 * @query If you want to have Wheels display the partial for each record in a query record set but want to override the name of the file referenced, provide the template file name for partial and pass the query as a separate query argument.
	 * @object If you want to have Wheels display the partial for a model object but want to override the name of the file referenced, provide the template file name for partial and pass the model object as a separate object argument.
	 * @objects If you want to have Wheels display the partial for each model object in an array but want to override the name of the file referenced, provide the template name for partial and pass the query as a separate objects argument.
	 */
	public string function includePartial(
		required any partial,
		string group = "",
		any cache = "",
		string layout,
		string spacer,
		any dataFunction,
		boolean $prependWithUnderscore = true
	) {
		$args(name = "includePartial", args = arguments);
		return $includeOrRenderPartial(
			argumentCollection = $dollarify(arguments, "partial,group,cache,layout,spacer,dataFunction")
		);
	}

	/**
	 * Includes content for the body section, which equates to the output generated by the view template run by the request.
	 *
	 * [section: View Helpers]
	 * [category: Miscellaneous Functions]
	 */
	public string function contentForLayout() {
		return includeContent("body");
	}

	/**
	 * Used to output the content for a particular section in a layout.
	 *
	 * [section: View Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @name Name of layout section to return content for.
	 * @defaultValue What to display as a default if the section is not defined.
	 */
	public string function includeContent(string name = "body", string defaultValue = "") {
		if (StructKeyExists(arguments, "default")) {
			arguments.defaultValue = arguments.default;
			StructDelete(arguments, "default");
		}
		if (StructKeyExists(variables.$instance.contentFor, arguments.name)) {
			local.rv = ArrayToList(variables.$instance.contentFor[arguments.name], Chr(10));
		} else {
			local.rv = arguments.defaultValue;
		}
		return local.rv;
	}

	/**
	 * Cycles through list values every time it is called.
	 *
	 * [section: View Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @values List of values to cycle through.
	 * @name Name to give the cycle. Useful when you use multiple cycles on a page.
	 */
	public string function cycle(required string values, string name = "default") {
		if (!StructKeyExists(request.wheels, "cycle")) {
			request.wheels.cycle = {};
		}
		if (!StructKeyExists(request.wheels.cycle, arguments.name)) {
			request.wheels.cycle[arguments.name] = ListGetAt(arguments.values, 1);
		} else {
			local.foundAt = ListFindNoCase(arguments.values, request.wheels.cycle[arguments.name]);
			if (local.foundAt == ListLen(arguments.values)) {
				local.foundAt = 0;
			}
			request.wheels.cycle[arguments.name] = ListGetAt(arguments.values, local.foundAt + 1);
		}
		return request.wheels.cycle[arguments.name];
	}

	/**
	 * Resets a cycle so that it starts from the first list value the next time it is called.
	 *
	 * [section: View Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @name The name of the cycle to reset.
	 */
	public void function resetCycle(string name = "default") {
		if (StructKeyExists(request.wheels, "cycle") && StructKeyExists(request.wheels.cycle, arguments.name)) {
			StructDelete(request.wheels.cycle, arguments.name);
		}
	}

	/**
	 * Internal function.
	 */
	public string function $tag(
		required string name,
		struct attributes = {},
		string skip = "",
		string skipStartingWith = "",
		boolean encode = false,
		string encodeExcept = ""
	) {
		// start the HTML tag and give it its name
		local.rv = "<" & arguments.name;

		// if named arguments are passed in we add these to the attributes argument instead so we can handle them all in the same code below
		if (StructCount(arguments) > 6) {
			for (local.key in arguments) {
				if (!ListFindNoCase("name,attributes,skip,skipStartingWith,encode,encodeExcept", local.key)) {
					arguments.attributes[local.key] = arguments[local.key];
				}
			}
		}

		/* To fix the bug below:
		   https://github.com/wheels-dev/wheels/issues/1115

		   Checked if "addClass" attribute is present then add that attribute's value to class so that it does not overwrite the default class value present in config/settings.cfm
		*/
		if(structKeyExists(arguments.attributes, 'addClass')) {
			if(structKeyExists(arguments.attributes, 'class')) {
				arguments.attributes.class = arguments.attributes.class & ' ' & arguments.attributes.addClass;
				structDelete(arguments.attributes, 'addClass');
			}
		}

		// add the names of the attributes and their values to the output string with a space in between (class="something" name="somethingelse" etc)
		// since the order of a struct can differ we sort the attributes in alphabetical order before placing them in the HTML tag (we could just place them in random order in the HTML but that would complicate testing for example)
		local.sortedKeys = ListSort(StructKeyList(arguments.attributes), "textnocase");
		local.sortedKeysArray = ListToArray(local.sortedKeys);
		local.iEnd = ArrayLen(local.sortedKeysArray);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.key = local.sortedKeysArray[local.i];
			// place the attribute name and value in the string unless it should be skipped according to the arguments or if it's an internal argument (starting with a "$" sign)
			if (
				!ListFindNoCase(arguments.skip, local.key)
				&& (
					!Len(arguments.skipStartingWith)
					|| Left(local.key, Len(arguments.skipStartingWith)) != arguments.skipStartingWith
				)
				&& Left(local.key, 1) != "$"
			) {
				if (IsSimpleValue(arguments.attributes[local.key])) {
					local.rv &= $tagAttribute(
						name = local.key,
						value = arguments.attributes[local.key],
						encode = arguments.encode,
						encodeExcept = arguments.encodeExcept
					);
				}
			}
		}

		// End the tag and return it.
		local.rv &= ">";
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $tagAttribute(
		required string name,
		required string value,
		required boolean encode,
		required string encodeExcept
	) {
		// For custom data attributes we convert underscores and camel case to hyphens.
		// E.g. "dataDomCache" and "data_dom_cache" becomes "data-dom-cache".
		// This is to get around the issue with not being able to use a hyphen in an argument name in CFML.
		if (Left(arguments.name, 5) == "data_") {
			arguments.name = Replace(arguments.name, "_", "-", "all");
		} else if (Left(arguments.name, 4) == "data") {
			arguments.name = hyphenize(arguments.name);
		}

		arguments.name = LCase(arguments.name);

		// set standard attribute name / value to use as the default to return (e.g. name / value part of <input name="value">)
		local.rv = " " & arguments.name & "=""";
		local.rv &= arguments.encode && !ListFind(arguments.encodeExcept, arguments.name) && $get("encodeHtmlAttributes")
			? EncodeForHTMLAttribute($canonicalize(arguments.value))
			: arguments.value;
		local.rv &= """";

		// when attribute can be boolean we handle it accordingly and override the above return value
		if (
			(
				!IsBoolean(application.wheels.booleanAttributes)
				&& ListFindNoCase(application.wheels.booleanAttributes, arguments.name)
			)
			|| (IsBoolean(application.wheels.booleanAttributes) && application.wheels.booleanAttributes)
		) {
			if (
				IsBoolean(arguments.value)
				|| !CompareNoCase(arguments.value, "true")
				|| !CompareNoCase(arguments.value, "false")
			) {
				// value passed in can be handled as a boolean
				if (arguments.value) {
					// when value is true we just add the attribute name itself (e.g. <input type="checkbox" checked>)
					local.rv = " " & arguments.name;
				} else {
					// when value is false we do not add the attribute at all
					local.rv = "";
				}
			}
		}
		return local.rv;
	}

	/**
	 * Creates an HTML element.
	 */
	public string function $element(
		required string name,
		struct attributes = {},
		string content = "",
		string skip = "",
		string skipStartingWith = "",
		any encode = false,
		string encodeExcept = ""
	) {
		// Set a variable with the content of the tag.
		// Encoded if global encode setting is true and true is also passed in to the function.
		local.rv = IsBoolean(arguments.encode) && arguments.encode && $get("encodeHtmlTags")
			? EncodeForHTML($canonicalize(arguments.content))
			: arguments.content;

		// When only wanting to encode HTML attribute values (and not tag content) we set the encode argument to true before passing on to $tag().
		if (arguments.encode == "attributes") {
			arguments.encode = true;
		}

		StructDelete(arguments, "content");
		return $tag(argumentCollection = arguments) & local.rv & "</" & arguments.name & ">";
	}

	/**
	 * Internal function.
	 */
	public any function $objectName(required any objectName, string association = "", string position = "") {
		local.currentModelObject = false;
		local.hasManyAssociationCount = 0;

		// combine our arguments
		$combineArguments(args = arguments, combine = "positions,position");
		$combineArguments(args = arguments, combine = "associations,association");

		if (IsObject(arguments.objectName)) {
			Throw(type = "Wheels.InvalidArgument", message = "The `objectName` argument passed is not of type string.");
		}

		// only try to create the object name if we have a simple value
		if (IsSimpleValue(arguments.objectName) && ListLen(arguments.associations)) {
			local.associationsArray = ListToArray(arguments.associations);
			local.positionsArray = ListToArray(arguments.positions);
			local.iEnd = ArrayLen(local.associationsArray);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.association = local.associationsArray[local.i];
				local.currentModelObject = $getObject(arguments.objectName);
				arguments.objectName &= "['" & local.association & "']";
				local.expanded = local.currentModelObject.$expandedAssociations(include = local.association);
				local.expanded = local.expanded[1];
				if (local.expanded.type == "hasMany") {
					local.hasManyAssociationCount++;
					if ($get("showErrorInformation") && local.hasManyAssociationCount > ArrayLen(local.positionsArray)) {
						Throw(
							type = "Wheels.InvalidArgument",
							message = "You passed the hasMany association of `#local.association#` but did not provide a corresponding position."
						);
					}
					arguments.objectName &= "[" & local.positionsArray[local.hasManyAssociationCount] & "]";
				}
			}
		}
		return arguments.objectName;
	}

	/**
	 * Internal function.
	 */
	public string function $tagId(required any objectName, required string property, string valueToAppend = "") {
		if (IsSimpleValue(arguments.objectName)) {
			// form element for object(s)
			local.rv = ListLast(arguments.objectName, ".");
			if (Find("[", local.rv)) {
				local.rv = $swapArrayPositionsForIds(objectName = local.rv);
			}
			if (Find("($", arguments.property)) {
				arguments.property = ReplaceList(arguments.property, "($,)", "-,");
			}
			if (Find("[", arguments.property)) {
				local.rv = ReReplace(ReReplace(local.rv & arguments.property, "[,\[]", "-", "all"), "[""'\]]", "", "all");
			} else {
				local.rv = ReReplace(ReReplace(local.rv & "-" & arguments.property, "[,\[]", "-", "all"), "[""'\]]", "", "all");
			}
		} else {
			local.rv = ReplaceList(arguments.property, "[,($,],',"",)", "-,-,");
		}
		if (Len(arguments.valueToAppend)) {
			local.rv &= "-" & arguments.valueToAppend;
		}
		return ReReplace(local.rv, "-+", "-", "all");
	}

	/**
	 * Internal function.
	 */
	public string function $tagName(required any objectName, required string property) {
		if (IsSimpleValue(arguments.objectName)) {
			local.rv = ListLast(arguments.objectName, ".");
			if (Find("[", local.rv)) {
				local.rv = $swapArrayPositionsForIds(objectName = local.rv);
			}
			if (Find("[", arguments.property)) {
				local.rv = ReplaceList(local.rv & arguments.property, "',""", "");
			} else {
				local.rv = ReplaceList(local.rv & "[" & arguments.property & "]", "',""", "");
			}
		} else {
			local.rv = arguments.property;
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $swapArrayPositionsForIds(required any objectName) {
		local.rv = arguments.objectName;

		// we could have multiple nested arrays so we need to traverse the objectName to find where we have array positions and
		// swap all of the out for object ids
		local.array = ListToArray(ReplaceList(local.rv, "],'", ""), "[", true);
		local.iEnd = ArrayLen(local.array);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			// if we find a digit, we need to replace it with an id
			if (ReFind("\d", local.array[local.i])) {
				// build our object reference
				local.objectReference = "";
				local.jEnd = local.i;
				for (local.j = 1; local.j <= local.jEnd; local.j++) {
					local.objectReference = ListAppend(local.objectReference, ListGetAt(arguments.objectName, local.j, "["), "[");
				}
				local.rv = ListSetAt(
					local.rv,
					local.i,
					$getObject(local.objectReference).key($returnTickCountWhenNew = true) & "]",
					"["
				);
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public any function $getObject(required string objectname, struct variableScope) {
		if(isNull(variableScope) || !isStruct(variableScope)){
			variableScope = variables;
		}
		try {
			if (Find(".", arguments.objectName) || Find("[", arguments.objectName)) {
				if(arguments.objectName.startsWith("request.")){
					local.rv = request[replaceNoCase(arguments.objectName, "request.", "", "one")];
				} else if(arguments.objectName.startsWith("variables.")){
					local.rv = variableScope[replaceNoCase(arguments.objectName, "variables.", "", "one")];
				} else{
					local.rv = $getValueByDynamicPath(arguments.objectName, variableScope);
				}
			} else {
				local.rv = variableScope[arguments.objectName];
			}
		} catch (any e) {
			if ($get("showErrorInformation")) {
				Throw(
					type = "Wheels.ObjectNotFound",
					message = "Wheels tried to find the model object `#arguments.objectName#` for the form helper, but it does not exist."
				);
			} else {
				Throw(object = e);
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public struct function $innerArgs(required string name, required struct args) {
		local.rv = {};
		local.element = arguments.name;
		for (local.key in arguments.args) {
			if (Left(local.key, Len(local.element)) == local.element) {
				local.name = LCase(Mid(local.key, Len(local.element) + 1, 1)) & Right(
					local.key,
					Len(local.key) - Len(local.element) - 1
				);
				local.rv[local.name] = arguments.args[local.key];
				StructDelete(arguments.args, local.key);
			}
		}
		return local.rv;
	}

	/**
	 * Function to dynamically resolve values based on a string path.
	 * @path The path to resolve the values from.
	 * @variableScope The scope from which to resolve the path from.
	 */
	public any function $getValueByDynamicPath(required string path, required struct variableScope) {
		// Extract keys and indexes using a regular expression
		local.pattern = "[a-zA-Z0-9_]+|\\['[^\\]]+'\\]";
		local.matches = REMatchNoCase(local.pattern, arguments.path);

		// Prepare the starting object
		local.currentObject = arguments.variableScope;

		for (key in local.matches) {
			// Dynamically navigate the object structures
			if (IsArray(local.currentObject) && IsNumeric(key)) {
				local.currentObject = local.currentObject[val(key)];
			}else if (StructKeyExists(local.currentObject, key)) {
				local.currentObject = local.currentObject[key];
			}
			else {
				return "Key not found: " & key;
			}
		}

		return local.currentObject;
	}
}
