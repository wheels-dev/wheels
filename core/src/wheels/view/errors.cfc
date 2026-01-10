component {
	/**
	 * Builds and returns a list (`ul` tag with a default `class` of `error-messages`) containing all the error messages for all the properties of the object.
	 * Returns an empty string if no errors exist.
	 *
	 * [section: View Helpers]
	 * [category: Error Functions]
	 *
	 * @objectName The variable name of the object to display error messages for.
	 * @class CSS `class` to set on the `ul` element.
	 * @showDuplicates Whether or not to show duplicate error messages.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function errorMessagesFor(
		required string objectName,
		string class,
		boolean showDuplicates,
		boolean encode,
		boolean includeAssociations = false
	) {
		$args(name = "errorMessagesFor", args = arguments);
		local.object = $getObject(arguments.objectName);
		if ($get("showErrorInformation") && !IsObject(local.object)) {
			Throw(type = "Wheels.IncorrectArguments", message = "The `#arguments.objectName#` variable is not an object.");
		}
		local.errors = local.object.allErrors(includeAssociations = arguments.includeAssociations);
		local.rv = "";
		if (!ArrayIsEmpty(local.errors)) {
			local.used = "";
			local.listItems = "";
			local.iEnd = ArrayLen(local.errors);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.msg = local.errors[local.i].message;
				if (arguments.showDuplicates) {
					local.listItems &= $element(name = "li", content = local.msg, encode = arguments.encode);
				} else {
					if (!ListFind(local.used, local.msg, Chr(7))) {
						local.listItems &= $element(name = "li", content = local.msg, encode = arguments.encode);
						local.used = ListAppend(local.used, local.msg, Chr(7));
					}
				}
			}
			local.encode = arguments.encode ? "attributes" : false;
			local.rv = $element(
				name = "ul",
				skip = "objectName,showDuplicates,encode,includeAssociations",
				content = local.listItems,
				attributes = arguments,
				encode = local.encode
			);
		}
		return local.rv;
	}

	/**
	 * Returns the error message, if one exists, on the object's property.
	 * If multiple error messages exist, the first one is returned.
	 *
	 * [section: View Helpers]
	 * [category: Error Functions]
	 *
	 * @objectName The variable name of the object to display the error message for.
	 * @property The name of the property to display the error message for.
	 * @prependText String to prepend to the error message.
	 * @appendText String to append to the error message.
	 * @wrapperElement HTML element to wrap the error message in.
	 * @class CSS `class` to set on the wrapper element.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function errorMessageOn(
		required string objectName,
		required string property,
		string prependText,
		string appendText,
		string wrapperElement,
		string class,
		boolean encode
	) {
		$args(name = "errorMessageOn", args = arguments);
		local.object = $getObject(arguments.objectName);
		if ($get("showErrorInformation") && !IsObject(local.object)) {
			Throw(type = "Wheels.IncorrectArguments", message = "The `#arguments.objectName#` variable is not an object.");
		}
		local.error = local.object.errorsOn(arguments.property);
		local.rv = "";
		if (!ArrayIsEmpty(local.error)) {
			// Encode all prepend / append type arguments if specified.
			if (arguments.encode && $get("encodeHtmlTags")) {
				if (Len(arguments.prependText)) {
					arguments.prependText = EncodeForHTML($canonicalize(arguments.prependText));
				}
				if (Len(arguments.appendText)) {
					arguments.appendText = EncodeForHTML($canonicalize(arguments.appendText));
				}
			}

			local.prepend = Len(arguments.prependText) ? arguments.prependText & (Right(arguments.prependText, 1) != " " ? " " : "") : "";
			local.append  = Len(arguments.appendText)  ? (Left(arguments.appendText, 1) != " " ? " " : "") & arguments.appendText : "";
			local.content = local.prepend & local.error[1].message & local.append;
			local.rv = $element(
				attributes = arguments,
				content = local.content,
				name = arguments.wrapperElement,
				skip = "objectName,property,prependText,appendText,wrapperElement,encode",
				encode = arguments.encode
			);
		}
		return local.rv;
	}
}
