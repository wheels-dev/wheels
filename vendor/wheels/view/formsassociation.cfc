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
		local.tagValue = arguments.tagValue;
		StructDelete(arguments, "keys");
		StructDelete(arguments, "objectName");
		StructDelete(arguments, "association");
		StructDelete(arguments, "property");
		StructDelete(arguments, "tagValue");
		StructDelete(arguments, "checkIfBlank");
		return radioButtonTag(
			name = local.tagName,
			id = local.tagId,
			value = local.tagValue,
			checked = local.checked,
			argumentCollection = arguments
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
	 * @keys Keys of the join row for this form field: the parent key, then the other key (for example a post key and a tag id). For a composite-key join model, list them in the order of its primary key columns. A surrogate-`id` join model works too: the keys are matched on its `belongsTo` foreign keys. Either way, declare a `belongsTo` association on the join model for each key column.
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
		local.tagId = (StructKeyExists(arguments, "id") && Len(Trim(arguments.id))) ? arguments.id : "#arguments.objectName#-#arguments.association#-#Replace(arguments.keys, ",", "-", "all")#-_delete";
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
		local.postedKeys = arguments.keys;

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
			if (
				IsObject(local.assoc)
				&& $nestedCollectionKeyMatches(
					parent = local.object,
					association = arguments.association,
					child = local.assoc,
					keys = local.postedKeys
				)
			) {
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
			if (
				IsObject(local.assoc)
				&& $nestedCollectionKeyMatches(
					parent = local.object,
					association = arguments.association,
					child = local.assoc,
					keys = arguments.keys
				)
				&& StructKeyExists(local.assoc, arguments.property)
			) {
				local.rv = local.assoc[arguments.property];
				break;
			}
		}
		return local.rv;
	}

	/**
	 * Internal function. True when a child object in a hasMany association is the
	 * row named by `keys`, the comma list the association form helpers post. The
	 * values are compared with the columns the parent maps that list onto (the
	 * child's primary key, or for a surrogate-key join model its foreign keys).
	 */
	public boolean function $nestedCollectionKeyMatches(
		required any parent,
		required string association,
		required any child,
		required string keys
	) {
		local.values = ListToArray(arguments.keys, ",", true);
		local.columns = arguments.parent.$nestedCollectionKeyColumns(
			association = arguments.association,
			keyCount = ArrayLen(local.values)
		);
		if (!Len(local.columns)) {
			return arguments.child.key() == ReReplace(arguments.keys, "^,|,$", "", "all");
		}
		local.iEnd = ListLen(local.columns);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.column = ListGetAt(local.columns, local.i);
			local.childValue = StructKeyExists(arguments.child, local.column) ? arguments.child[local.column] : "";
			if (!IsSimpleValue(local.childValue) || CompareNoCase(Trim(local.childValue), Trim(local.values[local.i])) != 0) {
				return false;
			}
		}
		return true;
	}
}
