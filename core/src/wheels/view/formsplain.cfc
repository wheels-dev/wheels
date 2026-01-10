component {
	/**
	 * Builds and returns a string containing a text field form control based on the supplied name.
	 * Note: Pass any additional arguments like `class`, `rel`, and `id`, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name Name to populate in tag's name attribute.
	 * @value Value to populate in tag's value attribute.
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @type [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function textFieldTag(
		required string name,
		string value = "",
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		string type = "text",
		any encode
	) {
		$args(name = "textFieldTag", args = arguments);
		arguments.property = arguments.name;
		arguments.objectName = {};
		arguments.objectName[arguments.name] = arguments.value;
		StructDelete(arguments, "name");
		StructDelete(arguments, "value");
		return textField(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing a password field form control based on the supplied name.
	 * Note: Pass any additional arguments like `class`, `rel`, and `id`, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @value [see:textFieldTag].
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function passwordFieldTag(
		required string name,
		string value = "",
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		any encode
	) {
		$args(name = "passwordFieldTag", args = arguments);
		arguments.property = arguments.name;
		arguments.objectName = {};
		arguments.objectName[arguments.name] = arguments.value;
		StructDelete(arguments, "name");
		StructDelete(arguments, "value");
		return passwordField(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing a hidden field form control based on the supplied name.
	 * Note: Pass any additional arguments like `class`, `rel`, and `id`, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @value [see:textFieldTag].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function hiddenFieldTag(required string name, string value = "", boolean encode) {
		arguments.property = arguments.name;
		arguments.objectName = {};
		arguments.objectName[arguments.name] = arguments.value;
		StructDelete(arguments, "name");
		StructDelete(arguments, "value");
		return hiddenField(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing a file form control based on the supplied name.
	 * Note: Pass any additional arguments like `class`, `rel`, and `id`, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function fileFieldTag(
		required string name,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		any encode
	) {
		$args(name = "fileFieldTag", args = arguments);
		arguments.property = arguments.name;
		arguments.objectName = {};
		arguments.objectName[arguments.name] = "";
		StructDelete(arguments, "name");
		return fileField(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing a text area form control based on the supplied name.
	 * Note: Pass any additional arguments like `class`, `rel`, and `id`, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @content Content to display in textarea on page load.
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function textAreaTag(
		required string name,
		string content = "",
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		any encode
	) {
		$args(name = "textAreaTag", args = arguments);
		arguments.property = arguments.name;
		arguments.objectName = {};
		arguments.objectName[arguments.name] = arguments.content;
		StructDelete(arguments, "name");
		StructDelete(arguments, "content");
		return textArea(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing a radio button form control based on the supplied name.
	 * Note: Pass any additional arguments like `class`, `rel`, and `id`, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @value [see:textFieldTag].
	 * @checked Whether or not to check the radio button by default.
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].*
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function radioButtonTag(
		required string name,
		required string value,
		boolean checked = false,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		any encode
	) {
		$args(name = "radioButtonTag", args = arguments);
		arguments.property = arguments.name;
		arguments.objectName = {};
		arguments.tagValue = arguments.value;
		if (arguments.checked) {
			arguments.objectName[arguments.name] = arguments.value;
		} else {
			// Space added to allow a blank value while still not having the form control checked.
			arguments.objectName[arguments.name] = " ";
		}
		StructDelete(arguments, "name");
		StructDelete(arguments, "value");
		StructDelete(arguments, "checked");
		return radioButton(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing a check box form control based on the supplied name.
	 * Note: Pass any additional arguments like `class`, `rel`, and `id`, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @checked Whether or not the check box should be checked by default.
	 * @value Value of check box in its checked state.
	 * @uncheckedValue The value of the check box when it's on the unchecked state.
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function checkBoxTag(
		required string name,
		boolean checked = false,
		string value,
		string uncheckedValue = "",
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		any encode
	) {
		$args(name = "checkBoxTag", args = arguments);
		arguments.checkedValue = arguments.value;
		arguments.property = arguments.name;
		arguments.objectName = {};
		if (arguments.checked) {
			arguments.objectName[arguments.name] = arguments.value;
		} else {
			// Space added to allow a blank value while still not having the form control checked.
			arguments.objectName[arguments.name] = " ";
		}
		if (!StructKeyExists(arguments, "id")) {
			local.valueToAppend = LCase(
				Replace(ReReplaceNoCase(arguments.checkedValue, "[^a-z0-9- ]", "", "all"), " ", "-", "all")
			);
			arguments.id = $tagId(arguments.objectName, arguments.property);
			if (Len(local.valueToAppend)) {
				arguments.id &= "-" & local.valueToAppend;
			}
		}
		StructDelete(arguments, "name");
		StructDelete(arguments, "value");
		StructDelete(arguments, "checked");
		return checkBox(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing a select form control based on the supplied name and options.
	 * Note: Pass any additional arguments like `class`, `rel`, and `id`, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @options [see:select].
	 * @selected Value of option that should be selected by default.
	 * @includeBlank [see:select].
	 * @multiple Whether to allow multiple selection of options in the select form control.
	 * @valueField [see:select].
	 * @textField [see:select].
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function selectTag(
		required string name,
		required any options,
		string selected = "",
		any includeBlank,
		boolean multiple,
		string valueField,
		string textField,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		any encode
	) {
		$args(name = "selectTag", args = arguments);
		arguments.property = arguments.name;
		arguments.objectName = {};
		arguments.objectName[arguments.name] = arguments.selected;
		StructDelete(arguments, "name");
		StructDelete(arguments, "selected");
		return select(argumentCollection = arguments);
	}
}
