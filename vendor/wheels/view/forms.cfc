component {
	/**
	 * Builds and returns a string containing the closing `form` tag.
	 *
	 * [section: View Helpers]
	 * [category: General Form Functions]
	 *
	 * @prepend [see:textField]
	 * @append [see:textField],
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function endFormTag(string prepend, string append, any encode) {
		$args(name = "endFormTag", args = arguments);

		// Encode all prepend / append type arguments if specified.
		if (IsBoolean(arguments.encode) && arguments.encode && $get("encodeHtmlTags")) {
			if (Len(arguments.prepend)) {
				arguments.prepend = EncodeForHTML($canonicalize(arguments.prepend));
			}
			if (Len(arguments.append)) {
				arguments.append = EncodeForHTML($canonicalize(arguments.append));
			}
		}
		arguments.encode = IsBoolean(arguments.encode) && !arguments.encode ? false : true;

		if (StructKeyExists(request.wheels, "currentFormMethod")) {
			StructDelete(request.wheels, "currentFormMethod");
		}
		return arguments.prepend & "</form>" & arguments.append;
	}

	/**
	 * Builds and returns a string containing the opening `form` tag.
	 * The form's action will be built according to the same rules as `URLFor`.
	 * Note: Pass any additional arguments like `class`, `rel`, and `id`, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: General Form Functions]
	 *
	 * @method The type of `method` to use in the `form` tag (`delete`, `get`, `patch`, `post`, and `put` are the options).
	 * @multipart Set to `true` if the form should be able to upload files.
	 * @route Name of a route that you have configured in `config/routes.cfm`.
	 * @controller Name of the controller to include in the URL.
	 * @action Name of the action to include in the URL.
	 * @key Key(s) to include in the URL.
	 * @params Any additional parameters to be set in the query string (example: wheels=cool&x=y). Please note that CFWheels uses the & and = characters to split the parameters and encode them properly for you. However, if you need to pass in & or = as part of the value, then you need to encode them (and only them), example: a=cats%26dogs%3Dtrouble!&b=1.
	 * @anchor Sets an anchor name to be appended to the path.
	 * @onlyPath If true, returns only the relative URL (no protocol, host name or port).
	 * @host Set this to override the current host.
	 * @protocol Set this to override the current protocol.
	 * @port Set this to override the current port number.
	 * @prepend String to prepend to the form control. Useful to wrap the form control with HTML tags.
	 * @append String to append to the form control. Useful to wrap the form control with HTML tags.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function startFormTag(
		string method,
		boolean multipart,
		string route = "",
		string controller = "",
		string action = "",
		any key = "",
		string params = "",
		string anchor = "",
		boolean onlyPath,
		string host,
		string protocol,
		numeric port,
		string prepend,
		string append,
		any encode
	) {
		$args(name = "startFormTag", args = arguments);
		local.routeAndMethodMatch = false;

		// Encode all prepend / append type arguments if specified.
		if (IsBoolean(arguments.encode) && arguments.encode && $get("encodeHtmlTags")) {
			if (Len(arguments.prepend)) {
				arguments.prepend = EncodeForHTML($canonicalize(arguments.prepend));
			}
			if (Len(arguments.append)) {
				arguments.append = EncodeForHTML($canonicalize(arguments.append));
			}
		}
		arguments.encode = IsBoolean(arguments.encode) && !arguments.encode ? false : true;

		// sets a flag to indicate whether we use get or post on this form, used when obfuscating params
		request.wheels.currentFormMethod = arguments.method;

		// Check to see if a route exists if not specified
		if (!Len(arguments.route) && Len(arguments.controller) && Len(arguments.action) && Len(arguments.method)) {
			for (local.route in application.wheels.routes) {
				if (
					StructKeyExists(local.route, "controller")
					&& local.route.controller == arguments.controller
					&& StructKeyExists(local.route, "action")
					&& local.route.action == arguments.action
					&& ListFindNoCase(local.route.methods, arguments.method)
				) {
					arguments.route = local.route.name;
					local.routeAndMethodMatch = true;
					break;
				}
			}
		}

		// if we have a route and method, tap
		if (Len(arguments.route) && StructKeyExists(arguments, "method")) {
			// Throw error if no route was found.
			if (!StructKeyExists(application.wheels.namedRoutePositions, arguments.route)) {
				$throwErrorOrShow404Page(
					type = "Wheels.RouteNotFound",
					message = "Could not find the `#arguments.route#` route.",
					extendedInfo = "Make sure there is a route configured in your `config/routes.cfm` file named `#arguments.route#`."
				);
			}

			// check to see if the route specified has a method to match the one passed in
			if (!local.routeAndMethodMatch) {
				for (local.position in ListToArray(application.wheels.namedRoutePositions[arguments.route])) {
					if (
						StructKeyExists(application.wheels.routes[local.position], "methods")
						&& ListFindNoCase(application.wheels.routes[local.position].methods, arguments.method)
					) {
						local.routeAndMethodMatch = true;
					}
				}
			}

			if (local.routeAndMethodMatch) {
				// save the method passed in
				local.method = arguments.method;

				if (arguments.method != "get") {
					arguments.method = "post";
				}
			}
		}

		// set the form's action attribute to the URL that we want to send to
		local.encodeExcept = "";
		if (!ReFindNoCase("^https?:\/\/", arguments.action)) {
			arguments.$encodeForHtmlAttribute = true;
			arguments.action = uRLFor(argumentCollection = arguments);
			local.encodeExcept = "action";
		}

		// set the form to be able to handle file uploads
		if (!StructKeyExists(arguments, "enctype") && arguments.multipart) {
			arguments.enctype = "multipart/form-data";
		}

		local.skip = "multipart,route,controller,key,params,anchor,onlyPath,host,protocol,port,prepend,append,encode";

		// variables passed in as route arguments should not be added to the html element
		if (Len(arguments.route)) {
			local.skip = ListAppend(local.skip, $routeVariables(argumentCollection = arguments));
		}

		// need to re-add action here even if it was removed due to being a route variable above
		if (ListFind(local.skip, "action")) {
			local.skip = ListDeleteAt(local.skip, ListFind(local.skip, "action"));
		}

		local.rv = arguments.prepend & $tag(
			name = "form",
			skip = local.skip,
			attributes = arguments,
			encode = arguments.encode,
			encodeExcept = local.encodeExcept
		) & arguments.append;
		if ($isRequestProtectedFromForgery() && ListFindNoCase("post,put,patch,delete", arguments.method)) {
			local.rv &= authenticityTokenField();
		}
		if (StructKeyExists(local, "method") && local.method != "get") {
			local.rv &= hiddenFieldTag(name = "_method", value = local.method);
		}
		return local.rv;
	}

	/**
	 * Builds and returns a string containing a submit button form control.
	 * Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: General Form Functions]
	 *
	 * @value Message to display in the button form control.
	 * @image File name of the image file to use in the button form control.
	 * @prepend [see:textField]
	 * @append [see:textField]
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function submitTag(string value, string image, string prepend, string append, any encode) {
		$args(name = "submitTag", reserved = "type,src", args = arguments);

		// Encode all prepend / append type arguments if specified.
		if (IsBoolean(arguments.encode) && arguments.encode && $get("encodeHtmlTags")) {
			if (Len(arguments.prepend)) {
				arguments.prepend = EncodeForHTML($canonicalize(arguments.prepend));
			}
			if (Len(arguments.append)) {
				arguments.append = EncodeForHTML($canonicalize(arguments.append));
			}
		}
		arguments.encode = IsBoolean(arguments.encode) && !arguments.encode ? false : true;

		local.rv = arguments.prepend;
		local.append = arguments.append;
		if (Len(arguments.image)) {
			// create an img tag and then just replace "img" with "input"
			arguments.type = "image";
			arguments.source = arguments.image;
			StructDelete(arguments, "value");
			StructDelete(arguments, "image");
			StructDelete(arguments, "append");
			StructDelete(arguments, "prepend");
			local.rv &= imageTag(argumentCollection = arguments);
			local.rv = Replace(local.rv, "<img", "<input");
		} else {
			arguments.type = "submit";
			local.rv &= $tag(
				name = "input",
				skip = "image,append,prepend,encode",
				attributes = arguments,
				encode = arguments.encode
			);
		}
		local.rv &= local.append;
		return local.rv;
	}

	/**
	 * Builds and returns a string containing a button form control.
	 *
	 * [section: View Helpers]
	 * [category: General Form Functions]
	 *
	 * @content Content to display inside the button.
	 * @type The type for the button: `button`, `reset`, or `submit`.
	 * @value The value of the button when submitted.
	 * @image File name of the image file to use in the button form control.
	 * @prepend [see:textField]
	 * @append [see:textField]
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function buttonTag(
		string content,
		string type,
		string value,
		string image,
		string prepend,
		string append,
		any encode
	) {
		$args(name = "buttonTag", args = arguments);

		// Encode all prepend / append type arguments if specified.
		if (IsBoolean(arguments.encode) && arguments.encode && $get("encodeHtmlTags")) {
			if (Len(arguments.prepend)) {
				arguments.prepend = EncodeForHTML($canonicalize(arguments.prepend));
			}
			if (Len(arguments.append)) {
				arguments.append = EncodeForHTML($canonicalize(arguments.append));
			}
		}

		// if image is specified then use that as the content
		if (Len(arguments.image)) {
			local.args = {};
			local.args.type = "image";
			local.args.source = arguments.image;
			local.args.encode = IsBoolean(arguments.encode) && !arguments.encode ? false : true;
			arguments.content = imageTag(argumentCollection = local.args);
			arguments.encode = arguments.encode ? "attributes" : false;
		}

		// save necessary info from arguments and delete afterwards
		local.content = arguments.content;
		local.prepend = arguments.prepend;
		local.append = arguments.append;
		local.encode = arguments.encode;
		StructDelete(arguments, "content");
		StructDelete(arguments, "image");
		StructDelete(arguments, "prepend");
		StructDelete(arguments, "append");
		StructDelete(arguments, "encode");

		// create the button
		return local.prepend & $element(
			name = "button",
			content = local.content,
			attributes = arguments,
			encode = local.encode
		) & local.append;
	}

	/**
	 * Internal function.
	 */
	public string function $formValue(required any objectName, required string property) {
		if (IsStruct(arguments.objectName)) {
			local.rv = arguments.objectName[arguments.property];
		} else {
			local.object = $getObject(arguments.objectName);
			if ($get("showErrorInformation") && !IsObject(local.object)) {
				Throw(type = "Wheels.IncorrectArguments", message = "The `#arguments.objectName#` variable is not an object.");
			}
			if (StructKeyExists(local.object, arguments.property)) {
				local.rv = local.object[arguments.property];
			} else {
				local.rv = "";
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public any function $maxLength(required any objectName, required string property) {
		if (StructKeyExists(arguments, "maxlength")) {
			local.rv = arguments.maxlength;
		} else if (!IsStruct(arguments.objectName)) {
			local.object = $getObject(arguments.objectName);
			if (IsObject(local.object)) {
				local.propertyInfo = local.object.$propertyInfo(arguments.property);
				if (StructCount(local.propertyInfo) && ListFindNoCase("cf_sql_char,cf_sql_varchar", local.propertyInfo.type)) {
					local.rv = local.propertyInfo.size;
				}
			}
		}
		if (StructKeyExists(local, "rv")) {
			return local.rv;
		}
	}

	/**
	 * Internal function.
	 */
	public boolean function $formHasError(required any objectName, required string property) {
		local.rv = false;
		if (!IsStruct(arguments.objectName)) {
			local.object = $getObject(arguments.objectName);
			if ($get("showErrorInformation") && !IsObject(local.object)) {
				Throw(type = "Wheels.IncorrectArguments", message = "The `#arguments.objectName#` variable is not an object.");
			}
			if (ArrayLen(local.object.errorsOn(arguments.property))) {
				local.rv = true;
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $createLabel(
		required any objectName,
		required string property,
		required string label,
		required string prependToLabel,
		any encode = false
	) {
		local.rv = arguments.prependToLabel;
		local.attributes = {};
		for (local.key in arguments) {
			if (CompareNoCase(Left(local.key, 5), "label") == 0 && Len(local.key) > 5 && local.key != "labelPlacement") {
				local.attributes[ReplaceNoCase(local.key, "label", "")] = arguments[local.key];
			}
		}
		if (StructKeyExists(arguments, "id")) {
			local.attributes.for = arguments.id;
		}
		local.rv &= $element(
			name = "label",
			content = arguments.label,
			attributes = local.attributes,
			encode = arguments.encode
		);
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $formBeforeElement(
		required any objectName,
		required string property,
		required any label,
		required string labelPlacement,
		required string prepend,
		required string append,
		required string prependToLabel,
		required string appendToLabel,
		required string errorElement,
		required string errorClass,
		any encode = false
	) {
		// Encode all prepend type arguments if specified.
		if (StructKeyExists(arguments, "encode") && IsBoolean(arguments.encode)) {
			if (arguments.encode && $get("encodeHtmlTags")) {
				if (Len(arguments.prepend)) {
					arguments.prepend = EncodeForHTML($canonicalize(arguments.prepend));
				}
				if (Len(arguments.prependToLabel)) {
					arguments.prependToLabel = EncodeForHTML($canonicalize(arguments.prependToLabel));
				}
			}
		}

		local.rv = "";
		arguments.label = $getFieldLabel(argumentCollection = arguments);
		if ($formHasError(argumentCollection = arguments) && Len(arguments.errorElement)) {
			// the input has an error and should be wrapped in a tag so we need to start that wrapper tag
			local.encode = IsBoolean(arguments.encode) && !arguments.encode ? false : true;
			local.rv &= $tag(name = arguments.errorElement, class = arguments.errorClass, encode = local.encode);
		}
		if (Len(arguments.label) && arguments.labelPlacement != "after") {
			local.rv &= $createLabel(argumentCollection = arguments);
			if (arguments.labelPlacement == "aroundRight") {
				// Strip out both the label text and closing label tag since it will be placed after the form input.
				// Needs to be done for both encoded and normal content.
				local.rv = Replace(local.rv, EncodeForHTML($canonicalize(arguments.label)) & "</label>", "");
				local.rv = Replace(local.rv, arguments.label & "</label>", "");
			} else if (arguments.labelPlacement == "before") {
				// since the entire label is created we can append to it
				local.rv &= arguments.appendToLabel;
			} else {
				// the label argument is either "around" or "aroundLeft" so we only have to strip out the closing label tag
				local.rv = Replace(local.rv, "</label>", "");
			}
		}
		local.rv &= arguments.prepend;
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $formAfterElement(
		required any objectName,
		required string property,
		required string label,
		required string labelPlacement,
		required string prepend,
		required string append,
		required string prependToLabel,
		required string appendToLabel,
		required string errorElement,
		any encode = false
	) {
		// Encode all append type arguments if specified.
		if (StructKeyExists(arguments, "encode") && IsBoolean(arguments.encode)) {
			if (arguments.encode && $get("encodeHtmlTags")) {
				if (Len(arguments.append)) {
					arguments.append = EncodeForHTML($canonicalize(arguments.append));
				}
				if (Len(arguments.appendToLabel)) {
					arguments.appendToLabel = EncodeForHTML($canonicalize(arguments.appendToLabel));
				}
			}
		}

		local.rv = arguments.append;
		arguments.label = $getFieldLabel(argumentCollection = arguments);
		if (Len(arguments.label) && arguments.labelPlacement != "before") {
			if (arguments.labelPlacement == "after") {
				// if the label should be placed after the tag we return the entire label tag
				local.rv &= $createLabel(argumentCollection = arguments);
			} else if (arguments.labelPlacement == "aroundRight") {
				// if the text should be placed to the right of the form input we return both the text and the closing tag
				local.rv &= arguments.label & "</label>";
			} else {
				// the label argument is either "around" or "aroundLeft" so we only have to return the closing label tag
				local.rv &= "</label>";
			}
			local.rv &= arguments.appendToLabel;
		}
		if ($formHasError(argumentCollection = arguments) && Len(arguments.errorElement)) {
			// the input has an error and is wrapped in a tag so we need to close that wrapper tag
			local.rv &= "</" & arguments.errorElement & ">";
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $getFieldLabel(required any objectName, required string property, required string label) {
		local.object = false;
		if (Compare("false", arguments.label) == 0) {
			local.rv = "";
		} else if (arguments.label == "useDefaultLabel" && !IsStruct(arguments.objectName)) {
			local.object = $getObject(arguments.objectName);
			if (IsObject(local.object)) {
				local.rv = local.object.$label(arguments.property);
			}
		}
		if (!StructKeyExists(local, "rv")) {
			local.rv = arguments.label;
		}
		return local.rv;
	}
}
