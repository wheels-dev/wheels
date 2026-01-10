component {
	/**
	 * Instructs the controller which view template and layout to render when it's finished processing the action.
	 * Note that when passing values for controller and / or action, this function does not execute the actual action but rather just loads the corresponding view template.
	 *
	 * [section: Controller]
	 * [category: Rendering Functions]
	 *
	 * @controller Controller to include the view page for.
	 * @action Action to include the view page for.
	 * @template A specific template to render. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder.
	 * @layout The layout to wrap the content in. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Pass `false` to not load a layout at all.
	 * @cache Number of minutes to cache the content for.
	 * @returnAs Set to `string` to return the result instead of automatically sending it to the client.
	 * @hideDebugInformation Set to `true` to hide the debug information at the end of the output. This is useful, for example, when you're testing XML output in an environment where the global setting for `showDebugInformation` is `true`.
	 * @status Force request to return with specific HTTP status code.
	 */
	public any function renderView(
		string controller = variables.params.controller,
		string action = variables.params.action,
		string template = "",
		any layout,
		any cache = "",
		string returnAs = "",
		boolean hideDebugInformation = false,
		string status = $statusCode()
	) {
		$args(name = "renderView", args = arguments);
		$dollarify(arguments, "controller,action,template,layout,cache,returnAs,hideDebugInformation");
		if ($get("showDebugInformation")) {
			$debugPoint("view");
		}

		// If no layout specific arguments were passed in use the this instance's layout.
		if (!Len(arguments.$layout)) {
			arguments.$layout = $useLayout(arguments.$action);
		}

		// Never show debugging out in AJAX requests.
		if (isAjax()) {
			arguments.$hideDebugInformation = true;
		}

		// If renderView was called with a layout set a flag to indicate that it's ok to show debug info at the end of the request.
		if (!arguments.$hideDebugInformation) {
			request.wheels.showDebugInformation = true;
		}

		$setRequestStatusCode(arguments.status);

		if ($get("cachePages") && (IsNumeric(arguments.$cache) || (IsBoolean(arguments.$cache) && arguments.$cache))) {
			local.category = "action";
			local.key = $hashedKey(arguments, variables.params);
			local.lockName = local.category & local.key & application.applicationName;
			local.conditionArgs = {};
			local.conditionArgs.category = local.category;
			local.conditionArgs.key = local.key;
			local.executeArgs = arguments;
			local.executeArgs.category = local.category;
			local.executeArgs.key = local.key;
			local.page = $doubleCheckedLock(
				condition = "$getFromCache",
				conditionArgs = local.conditionArgs,
				execute = "$renderViewAndAddToCache",
				executeArgs = local.executeArgs,
				name = local.lockName
			);
		} else {
			local.page = $renderView(argumentCollection = arguments);
		}
		if (arguments.$returnAs == "string") {
			local.rv = local.page;
		} else {
			variables.$instance.response = local.page;
		}
		if ($get("showDebugInformation")) {
			$debugPoint("view");
		}
		if (StructKeyExists(local, "rv")) {
			return local.rv;
		}
	}

	/**
	 * Instructs the controller to render an empty string when it's finished processing the action.
	 * This is very similar to calling `cfabort` with the advantage that any after filters you have set on the action will still be run.
	 *
	 * [section: Controller]
	 * [category: Rendering Functions]
	 *
	 * @status [see:renderView].
	 */
	public void function renderNothing(string status = $statusCode()) {
		$setRequestStatusCode(arguments.status);
		variables.$instance.response = "";
	}

	/**
	 * Instructs the controller to render specified text when it's finished processing the action.
	 *
	 * [section: Controller]
	 * [category: Rendering Functions]
	 *
	 * @text The text to render.
	 * @status [see:renderView].
	 */
	public void function renderText(string text = "", any status = $statusCode()) {
		$setRequestStatusCode(arguments.status);
		variables.$instance.response = arguments.text;
	}

	/**
	 * Instructs the controller to render a partial when it's finished processing the action.
	 *
	 * [section: Controller]
	 * [category: Rendering Functions]
	 *
	 * @partial The name of the partial file to be used. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Do not include the partial filename's underscore and file extension.
	 * @cache [see:renderView].
	 * @layout [see:renderView].
	 * @returnAs [see:renderView].
	 * @dataFunction Name of a controller function to load data from.
	 * @status [see:renderView].
	 */
	public any function renderPartial(
		required string partial,
		any cache = "",
		string layout,
		string returnAs = "",
		any dataFunction,
		string status = $statusCode()
	) {
		$args(name = "renderPartial", args = arguments);
		local.partial = $includeOrRenderPartial(
			argumentCollection = $dollarify(arguments, "partial,cache,layout,returnAs,dataFunction")
		);
		$setRequestStatusCode(arguments.status);
		if (arguments.$returnAs == "string") {
			local.rv = local.partial;
		} else {
			variables.$instance.response = local.partial;
		}
		if (StructKeyExists(local, "rv")) {
			return local.rv;
		}
	}

	/**
	 * Instructs the controller to render the data passed in to the format that is requested.
	 * If the format requested is `json` or `xml`, Wheels will transform the data into that format automatically.
	 * For other formats (or to override the automatic formatting), you can also create a view template in this format: `nameofaction.xml.cfm`, `nameofaction.json.cfm`, `nameofaction.pdf.cfm`, etc.
	 *
	 * [section: Controller]
	 * [category: Rendering Functions]
	 *
	 * @data Data to format and render.
	 * @controller [see:renderView].
	 * @action [see:renderView].
	 * @template [see:renderView].
	 * @layout [see:renderView].
	 * @cache [see:renderView].
	 * @returnAs [see:renderView].
	 * @hideDebugInformation [see:renderView].
	 * @status [see:renderView].
	 */
	public any function renderWith(
		required any data,
		string controller = variables.params.controller,
		string action = variables.params.action,
		string template = "",
		any layout,
		any cache = "",
		string returnAs = "",
		boolean hideDebugInformation = false,
		string status = $statusCode()
	) {
		$args(name = "renderWith", args = arguments);
		local.contentType = $requestContentType();
		local.acceptableFormats = $acceptableFormats(action = arguments.action);

		// Default to html if the content type found is not acceptable.
		if (!ListFindNoCase(local.acceptableFormats, local.contentType)) {
			local.contentType = "html";
		}

		$setRequestStatusCode(arguments.status);

		if (local.contentType == "html") {
			// Call render page when we are just rendering html.
			StructDelete(arguments, "data");
			local.rv = renderView(argumentCollection = arguments);
		} else {
			local.templateName = $generateRenderWithTemplatePath(
				argumentCollection = arguments,
				contentType = local.contentType
			);
			local.templatePathExists = $formatTemplatePathExists($name = local.templateName);
			if (local.templatePathExists) {
				local.content = renderView(
					argumentCollection = arguments,
					template = local.templateName,
					returnAs = "string",
					layout = false,
					hideDebugInformation = true
				);
			}

			// Throw an error if we rendered a pdf template and we got here, the cfdocument call should have stopped processing.
			if (local.contentType == "pdf" && $get("showErrorInformation") && local.templatePathExists) {
				Throw(
					type = "Wheels.PdfRenderingError",
					message = "When rendering the a PDF file, don't specify the filename attribute. This will stream the PDF straight to the browser."
				);
			}

			// Throw an error if we do not have a template to render the content type that we do not have defaults for.
			if (
				!ListFindNoCase("json,xml", local.contentType)
				&& !StructKeyExists(local, "content")
				&& $get("showErrorInformation")
			) {
				Throw(
					type = "Wheels.RenderingError",
					message = "To render the #local.contentType# content type, create the template `#local.templateName#.cfm` for the #arguments.controller# controller."
				);
			}

			// Set our header based on our mime type.
			local.formats = $get("formats");
			local.value = local.formats[local.contentType] & "; charset=utf-8";
			$header(name = "content-type", value = local.value, charset = "utf-8");

			// If we do not have the local.content variable and we are not rendering html then try to create it.
			if (!StructKeyExists(local, "content")) {
				if(isStruct(arguments.data)){
					for(local.item in arguments.data){
						if(isInstanceOf(arguments.data[local.item], "oracle.sql.TIMESTAMP")){
							arguments.data[local.item] = arguments.data[local.item].timestampValue();
						}
					}
				}
				switch (local.contentType) {
					case "json":
						local.namedArgs = {};
						if (StructCount(arguments) > 8) {
							local.namedArgs = $namedArguments(
								argumentCollection = arguments,
								$defined = "data,controller,action,template,layout,cache,returnAs,hideDebugInformation"
							);
						}
						for (local.key in local.namedArgs) {
							if (local.namedArgs[local.key] == "string") {
								if (IsArray(arguments.data)) {
									local.iEnd = ArrayLen(arguments.data);
									for (local.i = 1; local.i <= local.iEnd; local.i++) {
										// Force to string by wrapping in non printable character (that we later remove again).
										arguments.data[local.i][local.key] = Chr(7) & arguments.data[local.i][local.key] & Chr(7);
									}
								}
							}
						}
						local.content = SerializeJSON(arguments.data);
						if (Find(Chr(7), local.content)) {
							local.content = Replace(local.content, Chr(7), "", "all");
						}
						for (local.key in local.namedArgs) {
							if (local.namedArgs[local.key] == "integer") {
								// Force to integer by removing the .0 part of the number.
								local.content = ReReplaceNoCase(
									local.content,
									'([{|,]"' & local.key & '":[0-9]*)\.0([}|,"])',
									"\1\2",
									"all"
								);
							}
						}
						break;
					case "xml":
						local.content = $toXml(arguments.data);
						break;
				}
			}

			// If the developer passed in returnAs="string" then return the generated content to them.
			if (arguments.returnAs == "string") {
				local.rv = local.content;
			} else {
				renderText(text = local.content, status = arguments.status);
			}
		}
		if (StructKeyExists(local, "rv")) {
			return local.rv;
		}
	}


	/**
	 * Returns content that Wheels will send to the client in response to the request.
	 *
	 * [section: Controller]
	 * [category: Rendering Functions]
	 */
	public string function response() {
		if ($performedRender()) {
			return variables.$instance.response;
		} else {
			return "";
		}
	}

	/**
	 * Sets content that Wheels will send to the client in response to the request.
	 *
	 * [section: Controller]
	 * [category: Rendering Functions]
	 *
	 * @content The content to send to the client.
	 */
	public void function setResponse(required string content) {
		variables.$instance.response = arguments.content;
	}

	/**
	 * Primarily used for testing to establish whether the current request has performed a redirect.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 */
	public struct function getRedirect() {
		if ($performedRedirect()) {
			return variables.$instance.redirect;
		} else {
			return {};
		}
	}

	/**
	 * Primarily used for testing to get information about emails sent during the request.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 */
	public array function getEmails() {
		if ($sentEmails()) {
			return variables.$instance.emails;
		} else {
			return [];
		}
	}

	/**
	 * Primarily used for testing to get information about files sent during the request.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 */
	public array function getFiles() {
		if ($sentFiles()) {
			return variables.$instance.files;
		} else {
			return [];
		}
	}

	/**
	 * Internal function.
	 */
	public string function $renderViewAndAddToCache() {
		local.rv = $renderView(argumentCollection = arguments);
		if (!IsNumeric(arguments.$cache)) {
			arguments.$cache = $get("defaultCacheTime");
		}
		$addToCache(key = arguments.key, value = local.rv, time = arguments.$cache, category = arguments.category);
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $renderView() {
		if (!Len(arguments.$template)) {
			arguments.$template = "/" & ListChangeDelims(arguments.$controller, '/', '.') & "/" & arguments.$action;
		}
		arguments.$type = "page";
		arguments.$name = arguments.$template;
		arguments.$template = $generateIncludeTemplatePath(argumentCollection = arguments);
		local.content = $includeFile(argumentCollection = arguments);
		return $renderLayout($content = local.content, $layout = arguments.$layout, $type = arguments.$type);
	}

	/**
	 * Internal function.
	 */
	public string function $renderPartialAndAddToCache() {
		local.rv = $renderPartial(argumentCollection = arguments);
		if (!IsNumeric(arguments.$cache)) {
			arguments.$cache = $get("defaultCacheTime");
		}
		$addToCache(key = arguments.key, value = local.rv, time = arguments.$cache, category = arguments.category);
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public struct function $argumentsForPartial() {
		local.rv = {};
		if (StructKeyExists(arguments, "$dataFunction") && arguments.$dataFunction != false) {
			if (IsBoolean(arguments.$dataFunction)) {
				local.dataFunction = SpanExcluding(ListLast(arguments.$name, "/"), ".");
				if (StructKeyExists(variables, local.dataFunction)) {
					local.metaData = GetMetadata(variables[local.dataFunction]);
					if (
						IsStruct(local.metaData)
						&& StructKeyExists(local.metaData, "returnType")
						&& local.metaData.returnType == "struct"
						&& StructKeyExists(local.metaData, "access")
						&& local.metaData.access == "private"
					) {
						local.rv = $invoke(method = local.dataFunction, invokeArgs = arguments);
					}
				}
			} else {
				local.rv = $invoke(method = arguments.$dataFunction, invokeArgs = arguments);
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $renderPartial() {
		local.rv = "";
		if (IsQuery(arguments.$partial)) {
			Throw(
				type = "Wheels.InvalidPartialArguments",
				message = "To use a query with a partial, you must specify both `partial` and `query` arguments",
				extendedInfo = 'E.g. ##includePartial(partial="user", query="users")##'
			);
		} else if (IsObject(arguments.$partial)) {
			arguments.$name = arguments.$partial.$classData().modelName;
			arguments.object = arguments.$partial;
		} else if (IsArray(arguments.$partial) && ArrayLen(arguments.$partial)) {
			arguments.$name = arguments.$partial[1].$classData().modelName;
			arguments.objects = arguments.$partial;
		} else if (IsSimpleValue(arguments.$partial)) {
			arguments.$name = arguments.$partial;
		}
		if (StructKeyExists(arguments, "$name")) {
			arguments.$type = "partial";
			arguments.$template = $generateIncludeTemplatePath(argumentCollection = arguments);
			StructAppend(arguments, $argumentsForPartial(argumentCollection = arguments), false);
			local.content = $includeFile(argumentCollection = arguments);
			local.rv = $renderLayout($content = local.content, $layout = arguments.$layout, $type = arguments.$type);
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $includeOrRenderPartial() {
		if ($get("cachePartials") && (IsNumeric(arguments.$cache) || (IsBoolean(arguments.$cache) && arguments.$cache))) {
			local.category = "partial";
			local.key = $hashedKey(arguments);
			local.lockName = local.category & local.key & application.applicationName;
			local.conditionArgs = {};
			local.conditionArgs.category = local.category;
			local.conditionArgs.key = local.key;
			local.executeArgs = arguments;
			local.executeArgs.category = local.category;
			local.executeArgs.key = local.key;
			local.rv = $doubleCheckedLock(
				condition = "$getFromCache",
				conditionArgs = local.conditionArgs,
				execute = "$renderPartialAndAddToCache",
				executeArgs = local.executeArgs,
				name = local.lockName
			);
		} else {
			local.rv = $renderPartial(argumentCollection = arguments);
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $generateIncludeTemplatePath(
		required any $name,
		required any $type,
		string $controllerName = variables.params.controller,
		string $baseTemplatePath = $get("viewPath"),
		boolean $prependWithUnderscore = true
	) {
		local.rv = arguments.$baseTemplatePath;

		// Handle dot notation in the controller name.
		arguments.$controllerName = ListChangeDelims(arguments.$controllerName, '/', '.');

		// Extracts the file part of the path and replace ending ".cfm".
		local.fileName = ReplaceNoCase(Reverse(ListFirst(Reverse(arguments.$name), "/")), ".cfm", "", "all") & ".cfm";

		// Replace leading "_" when the file is a partial.
		if (arguments.$type == "partial" && arguments.$prependWithUnderscore) {
			local.fileName = Replace("_" & local.fileName, "__", "_", "one");
		}

		// BoxLang compatibility: Extract folder name more reliably
		if (structKeyExists(server, "boxlang")) {
			// For BoxLang, extract folder path manually to handle version differences
			local.tempName = arguments.$name;
			if (Find("/", local.tempName)) {
				local.folderName = Left(local.tempName, Len(local.tempName) - Len(ListLast(local.tempName, "/")));
				// Remove trailing slash if present, but only if there's more than just "/"
				if (Right(local.folderName, 1) == "/" AND Len(local.folderName) > 1) {
					local.folderName = Left(local.folderName, Len(local.folderName) - 1);
				}
				// If we end up with just "/", it means the file is at root level
				if (local.folderName == "/") {
					local.folderName = "";
				}
			} else {
				local.folderName = "";
			}
		} else {
			local.folderName = Reverse(ListRest(Reverse(arguments.$name), "/"));
		}

		if (Left(arguments.$name, 1) == "/") {
			// Include a file in a sub folder to views.
			local.rv &= local.folderName & "/" & local.fileName;
		} else if (Find("/", arguments.$name)) {
			// Include a file in a sub folder of the current controller.
			local.rv &= "/" & arguments.$controllerName & "/" & local.folderName & "/" & local.fileName;
		} else {
			// Include a file in the current controller's view folder.
			local.rv &= "/" & arguments.$controllerName & "/" & local.fileName;
		}
		return LCase(local.rv);
	}

	/**
	 * Internal function.
	 */
	public string function $includeFile(required any $name, required any $template, required any $type) {
		if (arguments.$type == "partial") {
			if (StructKeyExists(arguments, "query") && IsQuery(arguments.query)) {
				local.query = arguments.query;
				StructDelete(arguments, "query");
				local.rv = "";
				local.iEnd = local.query.recordCount;
				if (Len(arguments.$group)) {
					// We want to group based on a column so loop through the rows until we find, this will break if the query is not ordered by the grouped column.
					local.tempSpacer = "}|{";
					local.groupValue = "";
					local.groupQueryCount = 1;
					arguments.group = QueryNew(local.query.columnList);
					if ($get("showErrorInformation") && !ListFindNoCase(local.query.columnList, arguments.$group)) {
						Throw(
							type = "Wheels.GroupColumnNotFound",
							message = "Wheels couldn't find a query column with the name of `#arguments.$group#`.",
							extendedInfo = "Make sure your finder method has the column `#arguments.$group#` specified in the `select` argument. If the column does not exist, create it."
						);
					}
					for (local.i = 1; local.i <= local.iEnd; local.i++) {
						if (local.i == 1) {
							local.groupValue = local.query[arguments.$group][local.i];
						} else if (local.groupValue != local.query[arguments.$group][local.i]) {
							// We have a different group for this row so output what we have.
							local.rv &= $includeAndReturnOutput(argumentCollection = arguments);
							if (StructKeyExists(arguments, "$spacer")) {
								local.rv &= local.tempSpacer;
							}
							local.groupValue = local.query[arguments.$group][local.i];
							arguments.group = QueryNew(local.query.columnList);
							local.groupQueryCount = 1;
						}
						QueryAddRow(arguments.group);
						local.columnArray = ListToArray(local.query.columnList);
						local.jEnd = ArrayLen(local.columnArray);
						for (local.j = 1; local.j <= local.jEnd; local.j++) {
							local.property = local.columnArray[local.j];
							arguments[local.property] = local.query[local.property][local.i];
							QuerySetCell(arguments.group, local.property, local.query[local.property][local.i], local.groupQueryCount);
						}
						arguments.current = local.i + 1 - arguments.group.recordCount;
						local.groupQueryCount++;
					}

					// If we have anything left at the end we need to render it too.
					if (arguments.group.recordCount) {
						local.rv &= $includeAndReturnOutput(argumentCollection = arguments);
						if (StructKeyExists(arguments, "$spacer") && local.i < local.iEnd) {
							local.rv &= local.tempSpacer;
						}
					}

					// Now remove the last temp spacer and replace the tempSpacer with $spacer.
					if (Right(local.rv, 3) == local.tempSpacer) {
						local.rv = Left(local.rv, Len(local.rv) - 3);
					}
					local.rv = Replace(local.rv, local.tempSpacer, arguments.$spacer, "all");
				} else {
					for (local.i = 1; local.i <= local.iEnd; local.i++) {
						arguments.current = local.i;
						arguments.totalCount = local.iEnd;
						local.columnArray = ListToArray(local.query.columnList);
						local.jEnd = ArrayLen(local.columnArray);
						for (local.j = 1; local.j <= local.jEnd; local.j++) {
							local.property = local.columnArray[local.j];
							try {
								arguments[local.property] = local.query[local.property][local.i];
							} catch (any e) {
								arguments[local.property] = "";
							}
						}
						local.rv &= $includeAndReturnOutput(argumentCollection = arguments);
						if (StructKeyExists(arguments, "$spacer") && local.i < local.iEnd) {
							local.rv &= arguments.$spacer;
						}
					}
				}
			} else if (StructKeyExists(arguments, "object") && IsObject(arguments.object)) {
				local.modelName = arguments.object.$classData().modelName;
				arguments[local.modelName] = arguments.object;
				StructDelete(arguments, "object");
				StructAppend(arguments, arguments[local.modelName].properties(), false);
			} else if (StructKeyExists(arguments, "objects") && IsArray(arguments.objects)) {
				local.array = arguments.objects;
				StructDelete(arguments, "objects");
				local.originalArguments = Duplicate(arguments);
				local.modelName = local.array[1].$classData().modelName;
				local.rv = "";
				local.iEnd = ArrayLen(local.array);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					StructClear(arguments);
					StructAppend(arguments, local.originalArguments);
					arguments.current = local.i;
					arguments.totalCount = local.iEnd;
					arguments[local.modelName] = local.array[local.i];
					local.properties = local.array[local.i].properties();
					StructAppend(arguments, local.properties, true);
					local.rv &= $includeAndReturnOutput(argumentCollection = arguments);
					if (StructKeyExists(arguments, "$spacer") && local.i < local.iEnd) {
						local.rv &= arguments.$spacer;
					}
				}
			}
		}
		if (!StructKeyExists(local, "rv")) {
			local.rv = $includeAndReturnOutput(argumentCollection = arguments);
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public boolean function $formatTemplatePathExists(required string $name) {
		local.templatePath = $generateIncludeTemplatePath(
			$type = "page",
			$name = arguments.$name,
			$template = arguments.$name
		);
		local.rv = false;
		if (
			!ListFindNoCase(variables.$class.formats.existingTemplates, arguments.$name)
			&& !ListFindNoCase(variables.$class.formats.nonExistingTemplates, arguments.$name)
		) {
			if (FileExists(ExpandPath(local.templatePath))) {
				local.rv = true;
			}
			if ($get("cacheFileChecking")) {
				if (local.rv) {
					variables.$class.formats.existingTemplates = ListAppend(
						variables.$class.formats.existingTemplates,
						arguments.$name
					);
				} else {
					variables.$class.formats.nonExistingTemplates = ListAppend(
						variables.$class.formats.nonExistingTemplates,
						arguments.$name
					);
				}
			}
		}
		if (!local.rv && ListFindNoCase(variables.$class.formats.existingTemplates, arguments.$name)) {
			local.rv = true;
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $requestContentType(
		struct params = variables.params,
		string httpAccept = request.cgi.http_accept
	) {
		local.rv = "html";
		if (StructKeyExists(arguments.params, "format")) {
			local.rv = arguments.params.format;
		} else {
			local.formats = $get("formats");
			for (local.item in local.formats) {
				if (FindNoCase(local.formats[local.item], arguments.httpAccept)) {
					local.rv = local.item;
					break;
				}
			}
		}
		return local.rv;
	}

	/**
	 * Internal function. If custom statuscode passed in, then set appropriate header. Status may be a numeric value such as 404, or a text value such as "Forbidden".
	 */
	public void function $setRequestStatusCode(required string status) {
		local.status = arguments.status;
		if (IsNumeric(local.status)) {
			local.statusCode = local.status;
			local.statusText = $returnStatusText(local.status);
		} else {
			// Try for statuscode;
			local.statusCode = $returnStatusCode(local.status);
			local.statusText = local.status;
		}
		if (local.statusCode != $statusCode()) {
			$header(statusCode = local.statusCode);
		}
	}

	/**
	 * Returns a response text for any status code.
	 */
	public string function $returnStatusText(numeric status = 200) {
		local.status = arguments.status;
		local.statusCodes = $getStatusCodes();
		local.rv = "";
		if (StructKeyExists(local.statuscodes, local.status)) {
			local.rv = local.statuscodes[local.status];
		} else {
			Throw(type = "Wheels.RenderingError", message = "An invalid http response code #local.status# was passed in.");
		}
		return local.rv;
	}

	/**
	 * Returns a response code from the status code list.
	 */
	public string function $returnStatusCode(any status = 200) {
		local.status = arguments.status;
		local.statusCodes = $getStatusCodes();
		local.rv = "";
		local.lookup = StructFindValue(local.statuscodes, local.status);
		if (ArrayLen(local.lookup)) {
			local.rv = local.lookup[1]["key"];
		} else {
			Throw(type = "Wheels.RenderingError", message = "An invalid http response text #local.status# was passed in.");
		}
		return local.rv;
	}

	/**
	 * Returns a list of HTTP status codes and their response names
	 */
	public struct function $getStatusCodes() {
		local.rv = {
			100 = 'Continue',
			101 = 'Switching Protocols',
			102 = 'Processing',
			200 = 'OK',
			201 = 'Created',
			202 = 'Accepted',
			203 = 'Non-Authoritative Information',
			204 = 'No Content',
			205 = 'Reset Content',
			206 = 'Partial Content',
			207 = 'Multi-Status',
			208 = 'Already Reported',
			226 = 'IM Used',
			300 = 'Multiple Choices',
			301 = 'Moved Permanently',
			302 = 'Found',
			303 = 'See Other',
			304 = 'Not Modified',
			305 = 'Use Proxy',
			306 = 'Reserved',
			307 = 'Temporary Redirect',
			308 = 'Permanent Redirect',
			400 = 'Bad Request',
			401 = 'Unauthorized',
			402 = 'Payment Required',
			403 = 'Forbidden',
			404 = 'Not Found',
			405 = 'Method Not Allowed',
			406 = 'Not Acceptable',
			407 = 'Proxy Authentication Required',
			408 = 'Request Timeout',
			409 = 'Conflict',
			410 = 'Gone',
			411 = 'Length Required',
			412 = 'Precondition Failed',
			413 = 'Request Entity Too Large',
			414 = 'Request-URI Too Long',
			415 = 'Unsupported Media Type',
			416 = 'Requested Range Not Satisfiable',
			417 = 'Expectation Failed',
			418 = "I'm a teapot",
			422 = 'Unprocessable Entity',
			423 = 'Locked',
			424 = 'Failed Dependency',
			425 = 'Reserved for WebDAV advanced collections expired proposal',
			426 = 'Upgrade Required',
			427 = 'Unassigned',
			428 = 'Precondition Required',
			429 = 'Too Many Requests',
			430 = 'Unassigned',
			431 = 'Request Header Fields Too Large',
			500 = 'Internal Server Error',
			501 = 'Not Implemented',
			502 = 'Bad Gateway',
			503 = 'Service Unavailable',
			504 = 'Gateway Timeout',
			505 = 'HTTP Version Not Supported',
			506 = 'Variant Also Negotiates (Experimental)',
			507 = 'Insufficient Storage',
			508 = 'Loop Detected',
			509 = 'Unassigned',
			510 = 'Not Extended',
			511 = 'Network Authentication Required'
		};
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $acceptableFormats() {
		local.rv = variables.$class.formats.default;
		if (StructKeyExists(variables.$class.formats, arguments.action)) {
			local.rv = variables.$class.formats[arguments.action];
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $generateRenderWithTemplatePath(
		required string controller,
		required string action,
		required string template,
		required string contentType
	) {
		local.rv = "";
		if (!Len(arguments.template)) {
			local.rv = "/" & ListChangeDelims(arguments.controller, '/', '.') & "/" & arguments.action;
		} else {
			local.rv = arguments.template;
		}
		if (Len(arguments.contentType)) {
			local.rv &= "." & arguments.contentType;
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public boolean function $performedRenderOrRedirect() {
		if ($performedRender() || $performedRedirect()) {
			return true;
		} else {
			return false;
		}
	}

	/**
	 * Internal function.
	 */
	public boolean function $performedRender() {
		return StructKeyExists(variables.$instance, "response");
	}

	/**
	 * Internal function.
	 */
	public boolean function $performedRedirect() {
		return StructKeyExists(variables.$instance, "redirect");
	}

	/**
	 * Internal function.
	 */
	public boolean function $sentEmails() {
		return StructKeyExists(variables.$instance, "emails");
	}

	/**
	 * Internal function.
	 */
	public boolean function $sentFiles() {
		return StructKeyExists(variables.$instance, "files");
	}

	/**
	 * Internal function.
	 */
	public boolean function $abortIssued() {
		return StructKeyExists(variables.$instance, "abort");
	}

	/**
	 * Internal function.
	 */
	public boolean function $reCacheRequired() {
		return StructKeyExists(variables.$instance, "reCache") && variables.$instance.reCache;
	}
}
