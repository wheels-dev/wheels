component {
	/**
	 * Used as a shortcut to output the proper form elements for an association.
	 * Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Association Functions]
	 *
	 * @objectName Name of the variable containing the parent object to represent with this form field.
	 * @association Name of the association set in the parent object to represent with this form field.
	 * @property Name of the property in the child object to represent with this form field.
	 * @keys Primary keys associated with this form field. Note that these keys should be listed in the order that they appear in the database table.
	 * @tagValue The value of the radio button when selected.
	 * @checkIfBlank Whether or not to check this form field as a default if there is a blank value set for the property.
	 * @label The label text to use in the form control.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function hasManyRadioButton(
		required string objectName,
		required string association,
		required string property,
		required string keys,
		required string tagValue,
		boolean checkIfBlank = false,
		string label,
		any encode
	) {
		$args(name = "hasManyRadioButton", args = arguments);
		arguments.keys = Replace(arguments.keys, ", ", ",", "all");
		local.checked = false;
		local.rv = "";
		local.value = $hasManyFormValue(argumentCollection = arguments);
		local.included = includedInObject(argumentCollection = arguments);
		if (!local.included) {
			local.included = "";
		}
		if (local.value == arguments.tagValue || (arguments.checkIfBlank && local.value != arguments.tagValue)) {
			local.checked = true;
		}
		arguments.objectName = ListLast(arguments.objectName, ".");
		local.tagId = "#arguments.objectName#-#arguments.association#-#Replace(arguments.keys, ",", "-", "all")#-#arguments.property#-#arguments.tagValue#";
		local.tagName = "#arguments.objectName#[#arguments.association#][#arguments.keys#][#arguments.property#]";
		return radioButtonTag(
			name = local.tagName,
			id = local.tagId,
			value = arguments.tagValue,
			checked = local.checked,
			label = arguments.label,
			encode = arguments.encode
		);
	}

	/**
	 * Used as a shortcut to output the proper form elements for an association.
	 * Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.
	 *
	 * [section: View Helpers]
	 * [category: Form Association Functions]
	 *
	 * @objectName Name of the variable containing the parent object to represent with this form field.
	 * @association Name of the association set in the parent object to represent with this form field.
	 * @keys Primary keys associated with this form field. Note that these keys should be listed in the order that they appear in the database table.
	 * @id Optional. Explicit ID for the generated checkbox input. If not provided, an ID will be generated automatically.
	 * @label The label text to use in the form control.
	 * @labelPlacement Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using `aroundLeft` or `aroundRight`.
	 * @prepend String to prepend to the form control. Useful to wrap the form control with HTML tags.
	 * @append String to append to the form control. Useful to wrap the form control with HTML tags.
	 * @prependToLabel String to prepend to the form control's label. Useful to wrap the form control with HTML tags.
	 * @appendToLabel String to append to the form control's label. Useful to wrap the form control with HTML tags.
	 * @errorElement HTML tag to wrap the form control with when the object contains errors.
	 * @errorClass The `class` name of the HTML tag that wraps the form control when there are errors.
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function hasManyCheckBox(
		required string objectName,
		required string association,
		required string keys,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		string errorElement,
		string errorClass,
		any encode,
		string id
	) {
		$args(name = "hasManyCheckBox", args = arguments);
		arguments.keys = Replace(arguments.keys, ", ", ",", "all");
		local.checked = true;
		local.rv = "";
		local.included = includedInObject(argumentCollection = arguments);
		if (!local.included) {
			local.included = "";
			local.checked = false;
		}
		arguments.objectName = ListLast(arguments.objectName, ".");
		local.tagId = (len(trim(arguments.id))) ? arguments.id : "#arguments.objectName#-#arguments.association#-#Replace(arguments.keys, ",", "-", "all")#-_delete";
		local.tagName = "#arguments.objectName#[#arguments.association#][#arguments.keys#][_delete]";
		StructDelete(arguments, "keys");
		StructDelete(arguments, "objectName");
		StructDelete(arguments, "association");
		return checkBoxTag(
			name = local.tagName,
			id = local.tagId,
			value = 0,
			checked = local.checked,
			uncheckedValue = 1,
			argumentCollection = arguments
		);
	}

	/**
	 * Used as a shortcut to check if the specified IDs are a part of the main form object.
	 * This method should only be used for `hasMany` associations.
	 *
	 * [section: View Helpers]
	 * [category: Form Association Functions]
	 *
	 * @objectName Name of the variable containing the parent object to represent with this form field.
	 * @association Name of the association set in the parent object to represent with this form field.
	 * @keys Primary keys associated with this form field. Note that these keys should be listed in the order that they appear in the database table.
	 */
	public boolean function includedInObject(required string objectName, required string association, required string keys) {
		local.rv = false;
		local.object = $getObject(arguments.objectName);

		// clean up our key argument if there is a comma on the beginning or end
		arguments.keys = ReReplace(arguments.keys, "^,|,$", "", "all");

		if (!StructKeyExists(local.object, arguments.association) || !IsArray(local.object[arguments.association])) {
			return local.rv;
		}
		if (!Len(arguments.keys)) {
			return local.rv;
		}
		local.iEnd = ArrayLen(local.object[arguments.association]);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.assoc = local.object[arguments.association][local.i];
			if (IsObject(local.assoc) && local.assoc.key() == arguments.keys) {
				local.rv = local.i;
				break;
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $hasManyFormValue(
		required string objectName,
		required string association,
		required string property,
		required string keys
	) {
		local.rv = "";
		local.object = $getObject(arguments.objectName);
		if (!StructKeyExists(local.object, arguments.association) || !IsArray(local.object[arguments.association])) {
			return local.rv;
		}
		if (!Len(arguments.keys)) {
			return local.rv;
		}
		local.iEnd = ArrayLen(local.object[arguments.association]);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.assoc = local.object[arguments.association][local.i];
			if (IsObject(local.assoc) && local.assoc.key() == arguments.keys && StructKeyExists(local.assoc, arguments.property)) {
				local.rv = local.assoc[arguments.property];
				break;
			}
		}
		return local.rv;
	}
}
