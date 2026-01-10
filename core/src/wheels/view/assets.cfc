component {
	/**
	 * Returns a `link` tag for a stylesheet (or several) based on the supplied arguments.
	 *
	 * [section: View Helpers]
	 * [category: Asset Functions]
	 *
	 * @sources The name of one or many CSS files in the stylesheets folder, minus the `.css` extension. Pass a full URL to generate a tag for an external style sheet. Can also be called with the `source` argument.
	 * @type The `type` attribute for the `link` tag.
	 * @media The `media` attribute for the `link` tag.
	 * @rel  The `rel` attribute for the relation between the tag and href.
	 * @head Set to `true` to place the output in the `head` area of the HTML page instead of the default behavior (which is to place the output where the function is called from).
	 * @delim The delimiter to use for the list of CSS files.
	 * @encode Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content.
	 */
	public string function styleSheetLinkTag(
		string sources = "",
		string type,
		string media,
		string rel,
		boolean head,
		string delim = ",",
		boolean encode
	) {
		$args(name = "styleSheetLinkTag", args = arguments, combine = "sources/source/!", reserved = "href");
		if (!Len(arguments.type)) {
			StructDelete(arguments, "type");
		}
		if (!Len(arguments.media)) {
			StructDelete(arguments, "media");
		}
		if (!StructKeyExists(arguments, "rel") || !Len(arguments.rel)) {
			arguments.rel = "stylesheet";
		}

		local.rv = "";
		arguments.sources = $listClean(list = arguments.sources, returnAs = "array", delim = arguments.delim);
		local.iEnd = ArrayLen(arguments.sources);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = arguments.sources[local.i];
			if (ReFindNoCase("^(https?:)?\/\/", local.item)) {
				arguments.href = arguments.sources[local.i];
			} else {
				if (Left(local.item, 1) == "/") {
					arguments.href = $get("webPath") & Right(local.item, Len(local.item) - 1);
				} else {
					arguments.href = $get("webPath") & $get("stylesheetPath") & "/" & local.item;
				}
				if (!ListFindNoCase("css,cfm", ListLast(local.item, "."))) {
					arguments.href &= ".css";
				}
				arguments.href = $assetDomain(arguments.href) & $appendQueryString();
			}
			local.rv &= $tag(
				name = "link",
				skip = "sources,head,delim,encode",
				attributes = arguments,
				encode = arguments.encode
			) & Chr(10);
		}
		if (arguments.head) {
			$htmlhead(text = local.rv);
			local.rv = "";
		}
		return local.rv;
	}

	/**
	 * Returns a `script` tag for a JavaScript file (or several) based on the supplied arguments.
	 *
	 * [section: View Helpers]
	 * [category: Asset Functions]
	 *
	 * @sources The name of one or many JavaScript files in the `javascripts` folder, minus the `.js` extension. Pass a full URL to access an external JavaScript file. Can also be called with the `source` argument.
	 * @type The `type` attribute for the `script` tag.
	 * @head Set to `true` to place the output in the `head` area of the HTML page instead of the default behavior (which is to place the output where the function is called from).
	 * @delim The delimiter to use for the list of JavaScript files.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function javaScriptIncludeTag(
		string sources = "",
		string type,
		boolean head,
		string delim = ",",
		boolean encode
	) {
		$args(name = "javaScriptIncludeTag", args = arguments, combine = "sources/source/!", reserved = "src");
		if (!Len(arguments.type)) {
			StructDelete(arguments, "type");
		}
		local.rv = "";
		arguments.sources = $listClean(list = arguments.sources, returnAs = "array", delim = arguments.delim);
		local.iEnd = ArrayLen(arguments.sources);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = arguments.sources[local.i];
			if (ReFindNoCase("^(https?:)?\/\/", local.item)) {
				arguments.src = arguments.sources[local.i];
			} else {
				if (Left(local.item, 1) == "/") {
					arguments.src = $get("webPath") & Right(local.item, Len(local.item) - 1);
				} else {
					arguments.src = $get("webPath") & $get("javascriptPath") & "/" & local.item;
				}
				if (!ListFindNoCase("js,cfm", ListLast(local.item, "."))) {
					arguments.src &= ".js";
				}
				arguments.src = $assetDomain(arguments.src) & $appendQueryString();
			}
			local.rv &= $element(
				name = "script",
				skip = "sources,head,delim,encode",
				attributes = arguments,
				encode = arguments.encode
			) & Chr(10);
		}
		if (arguments.head) {
			$htmlhead(text = local.rv);
			local.rv = "";
		}
		return local.rv;
	}

	/**
	 * Returns an `img` tag.
	 * If the image is stored in the local `images` folder, the tag will also set the `width`, `height`, and `alt` attributes for you.
	 * You can pass any additional arguments (e.g. `class`, `rel`, `id`), and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Asset Functions]
	 *
	 * @source The file name of the image if it's available in the local file system (i.e. ColdFusion will be able to access it). Provide the full URL if the image is on a remote server.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function imageTag(
		required string source,
		boolean onlyPath,
		string host,
		string protocol,
		numeric port,
		boolean encode,
		boolean required = true
	) {
		$args(name = "imageTag", reserved = "src", args = arguments);

		// Ugly fix due to the fact that id can't be passed along to cfinvoke.
		if (StructKeyExists(arguments, "id")) {
			arguments.wheelsId = arguments.id;
			StructDelete(arguments, "id");
		}

		if ($get("cacheImages")) {
			local.category = "image";
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
				execute = "$addImageTagToCache",
				executeArgs = local.executeArgs,
				name = local.lockName
			);
		} else {
			local.rv = $imageTag(argumentCollection = arguments);
		}

		// Ugly fix continued.
		if (StructKeyExists(arguments, "wheelsId")) {
			local.rv = ReplaceNoCase(local.rv, "wheelsId", "id");
		}

		return local.rv;
	}

	/**
	 * Calls $imageTag and adds the result to the cache.
	 * Called from the imageTag function above if images are set to be cached and the image is not already in the cache.
	 */
	public string function $addImageTagToCache() {
		local.rv = $imageTag(argumentCollection = arguments);
		$addToCache(key = arguments.key, value = local.rv, category = arguments.category);
		return local.rv;
	}

	/**
	 * Called from the imageTag function above to do all of the work (create the tag, get width / height using cfimage etc).
	 */
	public string function $imageTag() {
		local.localFile = true;
		if (Left(arguments.source, 7) == "http://" || Left(arguments.source, 8) == "https://") {
			local.localFile = false;
		}
		if (!local.localFile) {
			arguments.src = arguments.source;
		} else {
			arguments.src = $get("webPath") & $get("imagePath") & "/" & arguments.source;
			//added this section for the "/wheels" mapping to work correctly
			if(arguments.source CONTAINS "/wheels"){
				local.file = expandPath(SpanExcluding(arguments.source, "?"));
			}
			else{
				local.file = GetDirectoryFromPath(GetBaseTemplatePath());
				local.file &= $get("imagePath") & "/" & SpanExcluding(arguments.source, "?");
			}
			if ($get("showErrorInformation") && arguments.required) {
				if (local.localFile && !FileExists(local.file)) {
					Throw(
						type = "Wheels.ImageFileNotFound",
						message = "Wheels could not find `#local.file#` on the local file system.",
						extendedInfo = "Pass in a correct relative path from the `images` folder to an image."
					);
				} else if (!IsImageFile(local.file)) {
					if (structKeyExists(server, "boxlang")) {
						Throw(
							type = "Wheels.ImageFormatNotSupported",
							message = "Wheels can't read image files with that format.",
							extendedInfo = "Use one of these image types instead: #ArrayToList(GetReadableImageFormats(), ', ')#."
						);
					} else {
						Throw(
							type = "Wheels.ImageFormatNotSupported",
							message = "Wheels can't read image files with that format.",
							extendedInfo = "Use one of these image types instead: #GetReadableImageFormats()#."
						);
					}	
				}
			}
			if (!StructKeyExists(arguments, "width") || !StructKeyExists(arguments, "height")) {
				if (arguments.required) {
					// Height and / or width arguments are missing so use cfimage to get them.
					local.image = $image(action = "info", source = local.file);
					if (!StructKeyExists(arguments, "width") && local.image.width > 0) {
						arguments.width = local.image.width;
					}
					if (!StructKeyExists(arguments, "height") && local.image.height > 0) {
						arguments.height = local.image.height;
					}
				}
			} else {
				// Remove height and width attributes if false.
				if (!arguments.width) {
					StructDelete(arguments, "width");
				}
				if (!arguments.height) {
					StructDelete(arguments, "height");
				}
			}

			// Only append a query string if the file is local.
			arguments.src = $assetDomain(arguments.src) & $appendQueryString();

			if (!arguments.onlyPath) {
				arguments.src = $prependUrl(path = arguments.src, argumentCollection = arguments);
			}
		}
		if (!StructKeyExists(arguments, "alt")) {
			arguments.alt = capitalize(
				ReplaceList(SpanExcluding(Reverse(SpanExcluding(Reverse(arguments.src), "/")), "."), "-,_", " , ")
			);
		}
		return $tag(
			name = "img",
			skip = "source,key,category,onlyPath,host,protocol,port,encode,required",
			attributes = arguments,
			encode = arguments.encode
		);
	}

	/**
	 * Appends a query string to the asset (a new query string is created on each app reload).
	 * Used to force local browser caches to refresh when there is an update to assets (CSS, JavaScript etc).
	 */
	public string function $appendQueryString() {
		local.rv = "";
		local.assetQueryString = $get("assetQueryString");

		// If assetQueryString is a boolean value, it means we just reloaded, so create a new query string based off of now.
		// The only problem with this is if the app doesn't get used a lot and the application is left alone for a period longer than the application scope is allowed to exist.
		if (IsBoolean(local.assetQueryString) && YesNoFormat(local.assetQueryString) == "no") {
			return local.rv;
		}
		if (!IsNumeric(local.assetQueryString) && IsBoolean(local.assetQueryString)) {
			local.assetQueryString = Hash(DateFormat(Now(), "yyyymmdd") & TimeFormat(Now(), "HHmmss"));
			$set(assetQueryString = local.assetQueryString);
		}

		local.rv &= "?" & local.assetQueryString;
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $assetDomain(required string pathToAsset) {
		local.rv = arguments.pathToAsset;
		local.assetPaths = $get("assetPaths");

		// Check for incorrect settings and throw errors.
		if ($get("showErrorInformation")) {
			if (!IsStruct(local.assetPaths) && !IsBoolean(local.assetPaths)) {
				Throw(type = "Wheels.IncorrectConfiguration", message = "The setting `assetsPaths` must be `false` or a struct.");
			}
			if (IsStruct(local.assetPaths) && !ListFindNoCase(StructKeyList(local.assetPaths), "http")) {
				Throw(type = "Wheels.IncorrectConfiguration", message = "The `assetPaths` struct must contain the key `http`");
			}
		}

		// Return nothing if assetPaths is not a struct.
		if (!IsStruct(local.assetPaths)) {
			return local.rv;
		}

		local.protocol = "http://";
		local.domainList = local.assetPaths.http;
		if (isSecure()) {
			local.protocol = "https://";
			if (StructKeyExists(local.assetPaths, "https")) {
				local.domainList = local.assetPaths.https;
			}
		}
		local.domainLen = ListLen(local.domainList);
		if (local.domainLen > 1) {
			// Now comes the interesting part, lets take the pathToAsset argument, hash it and create a number from it so that we can do mod based off the length of the domain list.
			// This is an easy way to apply the same sub-domain to each asset, so we do not create more work for the server.
			// At the same time we are getting a very random hash value to rotate the domains over the assets evenly.
			local.pathNumber = Right(ReReplace(Hash(arguments.pathToAsset), "[A-Za-z]", "", "all"), 5);
			local.position = (local.pathNumber % local.domainLen) + 1;
		} else {
			local.position = local.domainLen;
		}
		return local.protocol & Trim(ListGetAt(local.domainList, local.position)) & arguments.pathToAsset;
	}
}
