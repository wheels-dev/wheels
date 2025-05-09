component {
	/**
	 * Builds and returns a string containing a text field form control based on the supplied objectName and property.
	 * Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Object Functions]
	 *
	 * @objectName The variable name of the object to build the form control for.
	 * @property The name of the property to use in the form control.
	 * @association The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and CFWheels will figure it out.
	 * @position The position used when referencing a hasMany relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and CFWheels will figure it out.
	 * @label The label text to use in the form control.
	 * @labelPlacement Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight.
	 * @prepend String to prepend to the form control. Useful to wrap the form control with HTML tags.
	 * @append String to append to the form control. Useful to wrap the form control with HTML tags.
	 * @prependToLabel String to prepend to the form control's label. Useful to wrap the form control with HTML tags.
	 * @appendToLabel String to append to the form control's label. Useful to wrap the form control with HTML tags.
	 * @errorElement HTML tag to wrap the form control with when the object contains errors.
	 * @errorClass The class name of the HTML tag that wraps the form control when there are errors.
	 * @type Input type attribute. Common examples in HTML5 and later are text (default), email, tel, and url.
	 * @labelClass String added to the label's class.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function textField(
		required any objectName,
		required string property,
		string association,
		string position,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		string errorElement,
		string errorClass,
		string type = "text",
		any encode
	) {
		$args(name = "textField", reserved = "name", args = arguments);
		arguments.objectName = $objectName(argumentCollection = arguments);
		if (!StructKeyExists(arguments, "id")) {
			arguments.id = $tagId(arguments.objectName, arguments.property);
		}
		local.before = $formBeforeElement(argumentCollection = arguments);
		local.after = $formAfterElement(argumentCollection = arguments);
		arguments.name = $tagName(arguments.objectName, arguments.property);
		local.maxLength = $maxLength(argumentCollection = arguments);
		if (StructKeyExists(local, "maxLength")) {
			arguments.maxLength = local.maxLength;
		}
		if (!StructKeyExists(arguments, "value") || !Len(arguments.value)) {
			arguments.value = $formValue(argumentCollection = arguments);
		}
		local.encode = IsBoolean(arguments.encode) && !arguments.encode ? false : true;
		return local.before & $tag(
			name = "input",
			skip = "objectName,property,label,labelPlacement,prepend,append,prependToLabel,appendToLabel,errorElement,errorClass,association,position,encode",
			skipStartingWith = "label",
			attributes = arguments,
			encode = local.encode
		) & local.after;
	}

	/**
	 * Builds and returns a string containing a password field form control based on the supplied objectName and property.
	 * Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Object Functions]
	 *
	 * @objectName [see:textField].
	 * @property [see:textField].
	 * @association [see:textField].
	 * @position [see:textField].
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @errorElement [see:textField].
	 * @errorClass [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function passwordField(
		required any objectName,
		required string property,
		string association,
		string position,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		string errorElement,
		string errorClass,
		any encode
	) {
		$args(name = "passwordField", reserved = "type,name", args = arguments);
		arguments.objectName = $objectName(argumentCollection = arguments);
		if (!StructKeyExists(arguments, "id")) {
			arguments.id = $tagId(arguments.objectName, arguments.property);
		}
		local.before = $formBeforeElement(argumentCollection = arguments);
		local.after = $formAfterElement(argumentCollection = arguments);
		arguments.type = "password";
		arguments.name = $tagName(arguments.objectName, arguments.property);
		local.maxLength = $maxLength(argumentCollection = arguments);
		if (StructKeyExists(local, "maxLength")) {
			arguments.maxLength = local.maxLength;
		}
		if (!StructKeyExists(arguments, "value") || !Len(arguments.value)) {
			arguments.value = $formValue(argumentCollection = arguments);
		}
		local.encode = IsBoolean(arguments.encode) && !arguments.encode ? false : true;
		return local.before & $tag(
			name = "input",
			skip = "objectName,property,label,labelPlacement,prepend,append,prependToLabel,appendToLabel,errorElement,errorClass,association,position,encode",
			skipStartingWith = "label",
			attributes = arguments,
			encode = local.encode
		) & local.after;
	}

	/**
	 * Builds and returns a string containing a hidden field form control based on the supplied objectName and property.
	 * Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Object Functions]
	 *
	 * @objectName [see:textField].
	 * @property [see:textField].
	 * @association [see:textField].
	 * @position [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function hiddenField(
		required any objectName,
		required string property,
		string association,
		string position,
		boolean encode
	) {
		$args(name = "hiddenField", reserved = "type,name", args = arguments);
		arguments.objectName = $objectName(argumentCollection = arguments);
		arguments.type = "hidden";
		arguments.name = $tagName(arguments.objectName, arguments.property);
		if (!StructKeyExists(arguments, "id")) {
			arguments.id = $tagId(arguments.objectName, arguments.property);
		}
		if (!StructKeyExists(arguments, "value") || !Len(arguments.value)) {
			arguments.value = $formValue(argumentCollection = arguments);
		}
		if (
			application.wheels.obfuscateUrls
			&& StructKeyExists(request.wheels, "currentFormMethod")
			&& request.wheels.currentFormMethod == "get"
		) {
			arguments.value = obfuscateParam(arguments.value);
		}
		return $tag(
			name = "input",
			skip = "objectName,property,association,position,encode",
			attributes = arguments,
			encode = arguments.encode
		);
	}

	/**
	 * Builds and returns a string containing a file field form control based on the supplied objectName and property.
	 * Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Object Functions]
	 *
	 * @objectName [see:textField].
	 * @property [see:textField].
	 * @association [see:textField].
	 * @position [see:textField].
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @errorElement [see:textField].
	 * @errorClass [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function fileField(
		required any objectName,
		required string property,
		string association,
		string position,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		string errorElement,
		string errorClass,
		any encode
	) {
		$args(name = "fileField", reserved = "type,name", args = arguments);
		arguments.objectName = $objectName(argumentCollection = arguments);
		if (!StructKeyExists(arguments, "id")) {
			arguments.id = $tagId(arguments.objectName, arguments.property);
		}
		local.before = $formBeforeElement(argumentCollection = arguments);
		local.after = $formAfterElement(argumentCollection = arguments);
		arguments.type = "file";
		arguments.name = $tagName(arguments.objectName, arguments.property);
		local.encode = IsBoolean(arguments.encode) && !arguments.encode ? false : true;
		return local.before & $tag(
			name = "input",
			skip = "objectName,property,label,labelPlacement,prepend,append,prependToLabel,appendToLabel,errorElement,errorClass,association,position,encode",
			skipStartingWith = "label",
			attributes = arguments,
			encode = local.encode
		) & local.after;
	}

	/**
	 * Builds and returns a string containing a text area field form control based on the supplied objectName and property.
	 * Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Object Functions]
	 *
	 * @objectName [see:textField].
	 * @property [see:textField].
	 * @association [see:textField].
	 * @position [see:textField].
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @errorElement [see:textField].
	 * @errorClass [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function textArea(
		required any objectName,
		required string property,
		string association,
		string position,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		string errorElement,
		string errorClass,
		any encode
	) {
		$args(name = "textArea", reserved = "name", args = arguments);
		arguments.objectName = $objectName(argumentCollection = arguments);
		local.maxLength = $maxLength(argumentCollection = arguments);
		if (StructKeyExists(local, "maxLength")) {
			arguments.maxLength = local.maxLength;
		}
		if (!StructKeyExists(arguments, "id")) {
			arguments.id = $tagId(arguments.objectName, arguments.property);
		}
		local.before = $formBeforeElement(argumentCollection = arguments);
		local.after = $formAfterElement(argumentCollection = arguments);
		arguments.name = $tagName(arguments.objectName, arguments.property);
		local.content = $formValue(argumentCollection = arguments);
		return local.before & $element(
			name = "textarea",
			skip = "objectName,property,label,labelPlacement,prepend,append,prependToLabel,appendToLabel,errorElement,errorClass,association,position,encode",
			skipStartingWith = "label",
			content = local.content,
			attributes = arguments,
			encode = arguments.encode
		) & local.after;
	}

	/**
	 * Builds and returns a string containing a radio button form control based on the supplied objectName and property.
	 * Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Object Functions]
	 *
	 * @objectName [see:textField].
	 * @property [see:textField].
	 * @association [see:textField].
	 * @position [see:textField].
	 * @tagValue The value of the radio button when selected.
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @errorElement [see:textField].
	 * @errorClass [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function radioButton(
		required any objectName,
		required string property,
		string association,
		string position,
		string tagValue,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		string errorElement,
		string errorClass,
		any encode
	) {
		$args(name = "radioButton", reserved = "type,name,value,checked", args = arguments);
		arguments.objectName = $objectName(argumentCollection = arguments);
		local.valueToAppend = LCase(Replace(ReReplaceNoCase(arguments.tagValue, "[^a-z0-9- ]", "", "all"), " ", "-", "all"));
		if (!StructKeyExists(arguments, "id")) {
			arguments.id = $tagId(arguments.objectName, arguments.property);
			if (Len(local.valueToAppend)) {
				arguments.id &= "-" & local.valueToAppend;
			}
		}
		local.before = $formBeforeElement(argumentCollection = arguments);
		local.after = $formAfterElement(argumentCollection = arguments);
		arguments.type = "radio";
		arguments.name = $tagName(arguments.objectName, arguments.property);
		arguments.value = arguments.tagValue;
		if (arguments.tagValue == $formValue(argumentCollection = arguments)) {
			arguments.checked = "checked";
		}
		local.encode = IsBoolean(arguments.encode) && !arguments.encode ? false : true;
		return local.before & $tag(
			name = "input",
			skip = "objectName,property,tagValue,label,labelPlacement,prepend,append,prependToLabel,appendToLabel,errorElement,errorClass,association,position,encode",
			skipStartingWith = "label",
			attributes = arguments,
			encode = local.encode
		) & local.after;
	}

	/**
	 * Builds and returns a string containing a check box form control based on the supplied name.
	 * Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Object Functions]
	 *
	 * @objectName [see:textField].
	 * @property [see:textField].
	 * @association [see:textField].
	 * @position [see:textField].
	 * @value Value of check box in its checked state.
	 * @uncheckedValue The value of the check box when it's on the unchecked state.
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @errorElement [see:textField].
	 * @errorClass [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function checkBox(
		required any objectName,
		required string property,
		string association,
		string position,
		string checkedValue,
		string uncheckedValue,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		string errorElement,
		string errorClass,
		any encode
	) {
		$args(name = "checkBox", reserved = "type,name,value,checked", args = arguments);
		arguments.objectName = $objectName(argumentCollection = arguments);
		if (!StructKeyExists(arguments, "id")) {
			arguments.id = $tagId(arguments.objectName, arguments.property);
		}
		local.before = $formBeforeElement(argumentCollection = arguments);
		local.after = $formAfterElement(argumentCollection = arguments);
		arguments.type = "checkbox";
		arguments.name = $tagName(arguments.objectName, arguments.property);
		arguments.value = arguments.checkedValue;
		local.value = $formValue(argumentCollection = arguments);
		// either the property value & checkedValue are equal or assume the checkedValue is a truthy value
		if (
			local.value == arguments.value
			|| (!Len(arguments.checkedValue)
				&& (
					(IsNumeric(local.value) && local.value == 1)
					|| (!IsNumeric(local.value) && IsBoolean(local.value) && local.value)
				)
			)
		) {
			arguments.checked = "checked";
		}
		local.encode = IsBoolean(arguments.encode) && !arguments.encode ? false : true;
		local.rv = local.before & $tag(
			name = "input",
			skip = "objectName,property,checkedValue,uncheckedValue,label,labelPlacement,prepend,append,prependToLabel,appendToLabel,errorElement,errorClass,association,position,encode",
			skipStartingWith = "label",
			attributes = arguments,
			encode = local.encode
		);
		if (Len(arguments.uncheckedValue)) {
			local.hiddenAttributes = {};
			local.hiddenAttributes.type = "hidden";
			local.hiddenAttributes.id = arguments.id & "-checkbox";
			local.hiddenAttributes.name = arguments.name & "($checkbox)";
			local.hiddenAttributes.value = arguments.uncheckedValue;
			local.rv &= $tag(name = "input", attributes = local.hiddenAttributes, encode = local.encode);
		}
		local.rv &= local.after;
		return local.rv;
	}

	/**
	 * Builds and returns a string containing a select form control based on the supplied objectName and property.
	 * Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Object Functions]
	 *
	 * @objectName [see:textField].
	 * @property [see:textField].
	 * @association [see:textField].
	 * @position [see:textField].
	 * @options A collection to populate the select form control with. Can be a query recordSet or an array of objects.
	 * @includeBlank Whether to include a blank option in the select form control. Pass true to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -").
	 * @valueField The column or property to use for the value of each list element. Used only when a query or array of objects has been supplied in the options argument.  Required when specifying `textField`
	 * @textField The column or property to use for the value of each list element that the end user will see. Used only when a query or array of objects has been supplied in the options argument. Required when specifying `valueField`
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @errorElement [see:textField].
	 * @errorClass [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function select(
		required any objectName,
		required string property,
		string association,
		string position,
		any options,
		any includeBlank,
		string valueField,
		string textField,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		string errorElement,
		string errorClass,
		any encode
	) {
		$args(name = "select", reserved = "name", args = arguments);
		arguments.objectName = $objectName(argumentCollection = arguments);
		if (!StructKeyExists(arguments, "id")) {
			arguments.id = $tagId(arguments.objectName, arguments.property);
		}
		local.before = $formBeforeElement(argumentCollection = arguments);
		local.after = $formAfterElement(argumentCollection = arguments);
		arguments.name = $tagName(arguments.objectName, arguments.property);
		if (StructKeyExists(arguments, "multiple") && IsBoolean(arguments.multiple)) {
			if (arguments.multiple) {
				arguments.multiple = "multiple";
			} else {
				StructDelete(arguments, "multiple");
			}
		}
		local.content = $optionsForSelect(argumentCollection = arguments);
		if (!IsBoolean(arguments.includeBlank) || arguments.includeBlank) {
			if (!IsBoolean(arguments.includeBlank)) {
				local.blankOptionText = arguments.includeBlank;
			} else {
				local.blankOptionText = "";
			}
			local.blankOptionAttributes = {value = ""};
			local.content = $element(
				name = "option",
				content = local.blankOptionText,
				attributes = local.blankOptionAttributes,
				encode = arguments.encode
			) & local.content;
		}
		local.encode = IsBoolean(arguments.encode) && !arguments.encode ? false : "attributes";
		return local.before & $element(
			name = "select",
			skip = "objectName,property,options,includeBlank,valueField,textField,label,labelPlacement,prepend,append,prependToLabel,appendToLabel,errorElement,errorClass,association,position,encode",
			skipStartingWith = "label",
			content = local.content,
			attributes = arguments,
			encode = local.encode
		) & local.after;
	}

	/**
	 * Creates multiple HTML "option" elements.
	 */
	public string function $optionsForSelect(
		required any options,
		required string valueField,
		required string textField,
		required any encode
	) {
		local.value = $formValue(argumentCollection = arguments);
		local.rv = "";
		if (IsQuery(arguments.options)) {
			if (!Len(arguments.valueField) || !Len(arguments.textField)) {
				// order the columns according to their ordinal position in the database table
				local.columns = "";
				local.info = GetMetadata(arguments.options);
				local.iEnd = ArrayLen(local.info);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.columns = ListAppend(local.columns, local.info[local.i].name);
				}
				if (!Len(local.columns)) {
					arguments.valueField = "";
					arguments.textField = "";
				} else if (ListLen(local.columns) == 1) {
					arguments.valueField = ListGetAt(local.columns, 1);
					arguments.textField = ListGetAt(local.columns, 1);
				} else {
					// take the first numeric field in the query as the value field and the first non numeric as the text field
					local.iEnd = arguments.options.RecordCount;
					for (local.i = 1; local.i <= local.iEnd; local.i++) {
						local.jEnd = ListLen(local.columns);
						for (local.j = 1; local.j <= local.jEnd; local.j++) {
							if (!Len(arguments.valueField) && IsNumeric(arguments.options[ListGetAt(local.columns, local.j)][local.i])) {
								arguments.valueField = ListGetAt(local.columns, local.j);
							}
							if (!Len(arguments.textField) && !IsNumeric(arguments.options[ListGetAt(local.columns, local.j)][local.i])) {
								arguments.textField = ListGetAt(local.columns, local.j);
							}
						}
					}
					if (!Len(arguments.valueField) || !Len(arguments.textField)) {
						// the query does not contain both a numeric and a text column so we'll just use the first and second column instead
						arguments.valueField = ListGetAt(local.columns, 1);
						arguments.textField = ListGetAt(local.columns, 2);
					}
				}
			}
			local.iEnd = arguments.options.RecordCount;
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.rv &= $option(
					objectValue = local.value,
					optionValue = arguments.options[arguments.valueField][local.i],
					optionText = arguments.options[arguments.textField][local.i],
					encode = arguments.encode
				);
			}
		} else if (IsStruct(arguments.options)) {
			// Sort struct keys alphabetically.
			local.sortedKeys = ListSort(StructKeyList(arguments.options), "textnocase");

			local.iEnd = ListLen(local.sortedKeys);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.key = ListGetAt(local.sortedKeys, local.i);
				local.rv &= $option(
					objectValue = local.value,
					optionValue = LCase(local.key),
					optionText = arguments.options[local.key],
					encode = arguments.encode
				);
			}
		} else {
			// Convert the options to an array so we don't duplicate logic.
			if (IsSimpleValue(arguments.options)) {
				arguments.options = ListToArray(arguments.options);
			}

			local.iEnd = ArrayLen(arguments.options);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.optionValue = "";
				local.optionText = "";
				// see if the value in the array cell is an array, which means the programmer is using multidimensional arrays. if it is, use the first dimension for the key and the second for the value if it exists.
				if (IsSimpleValue(arguments.options[local.i])) {
					local.optionValue = arguments.options[local.i];
					local.optionText = humanize(arguments.options[local.i]);
				} else if (IsArray(arguments.options[local.i]) && ArrayLen(arguments.options[local.i]) >= 2) {
					local.optionValue = arguments.options[local.i][1];
					local.optionText = arguments.options[local.i][2];
				} else if (
					IsStruct(arguments.options[local.i])
					&& StructKeyExists(arguments.options[local.i], "value")
					&& StructKeyExists(arguments.options[local.i], "text")
				) {
					local.optionValue = arguments.options[local.i]["value"];
					local.optionText = arguments.options[local.i]["text"];
				} else if (IsObject(arguments.options[local.i])) {
					local.object = arguments.options[local.i];
					if (!Len(arguments.valueField) || !Len(arguments.textField)) {
						local.propertyNames = local.object.propertyNames();
						local.jEnd = ListLen(local.propertyNames);
						for (local.j = 1; local.j <= local.jEnd; local.j++) {
							local.propertyName = ListGetAt(local.propertyNames, local.j);
							if (StructKeyExists(local.object, local.propertyName)) {
								local.propertyValue = local.object[local.propertyName];
								if (!Len(arguments.valueField) && IsNumeric(local.propertyValue)) {
									arguments.valueField = local.propertyName;
								}
								if (!Len(arguments.textField) && !IsNumeric(local.propertyValue)) {
									arguments.textField = local.propertyName;
								}
							}
						}
					}
					if (StructKeyExists(local.object, arguments.valueField)) {
						local.optionValue = local.object[arguments.valueField];
					}
					if (StructKeyExists(local.object, arguments.textField)) {
						local.optionText = local.object[arguments.textField];
					}
				} else if (IsStruct(arguments.options[local.i])) {
					local.object = arguments.options[local.i];
					if (StructCount(local.object) == 1) {
						// When the struct only has one element then use the key / value pair.
						local.key = StructKeyList(local.object);
						local.optionValue = LCase(local.key);
						local.optionText = local.object[local.key];
					} else {
						if (StructKeyExists(local.object, arguments.valueField)) {
							local.optionValue = local.object[arguments.valueField];
						}
						if (StructKeyExists(local.object, arguments.textField)) {
							local.optionText = local.object[arguments.textField];
						}
					}
				}
				local.rv &= $option(
					objectValue = local.value,
					optionValue = local.optionValue,
					optionText = local.optionText,
					encode = arguments.encode
				);
			}
		}
		return local.rv;
	}

	/**
	 * Creates an HTML "option" element.
	 */
	public string function $option(
		required string objectValue,
		required string optionValue,
		required string optionText,
		required any encode
	) {
		local.optionAttributes = {value = arguments.optionValue};
		if (arguments.optionValue == arguments.objectValue || ListFindNoCase(arguments.objectValue, arguments.optionValue)) {
			local.optionAttributes.selected = "selected";
		}
		if (
			application.wheels.obfuscateUrls
			&& StructKeyExists(request.wheels, "currentFormMethod")
			&& request.wheels.currentFormMethod == "get"
		) {
			local.optionAttributes.value = obfuscateParam(local.optionAttributes.value);
		}
		return $element(
			name = "option",
			content = arguments.optionText,
			attributes = local.optionAttributes,
			encode = arguments.encode
		);
	}
}
