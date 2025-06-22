component {
	/**
	 * Builds and returns a string containing three `select` form controls for month, day, and year based on the supplied `objectName` and `property`.
	 *
	 * [section: View Helpers]
	 * [category: Form Object Functions]
	 *
	 * @objectName The variable name of the object to build the form control for.
	 * @property The name of the property to use in the form control.
	 * @association The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and CFWheels will figure it out.
	 * @position The position used when referencing a `hasMany` relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and CFWheels will figure it out.
	 * @order Use to change the order of or exclude date `select` tags.
	 * @separator Use to change the character that is displayed between the date `select` tags.
	 * @startYear First year in `select` list.
	 * @endYear Last year in `select` list.
	 * @monthDisplay Pass in names, numbers, or abbreviations to control display.
	 * @includeBlank Whether to include a blank option in the `select` form control. Pass `true` to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -").
	 * @label The label text to use in the form control.
	 * @labelPlacement Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using `aroundLeft` or `aroundRight`.
	 * @prepend String to prepend to the form control. Useful to wrap the form control with HTML tags.
	 * @append String to append to the form control. Useful to wrap the form control with HTML tags.
	 * @prependToLabel String to prepend to the form control's label. Useful to wrap the form control with HTML tags.
	 * @appendToLabel String to append to the form control's label. Useful to wrap the form control with HTML tags.
	 * @errorElement HTML tag to wrap the form control with when the object contains errors.
	 * @errorClass The `class` name of the HTML tag that wraps the form control when there are errors.
	 * @combine [see:dateTimeSelect].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function dateSelect(
		any objectName = "",
		string property = "",
		string association,
		string position,
		string order,
		string separator,
		numeric startYear,
		numeric endYear,
		string monthDisplay,
		string monthNames,
		string monthAbbreviations,
		any includeBlank,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		string errorElement,
		string errorClass,
		boolean combine,
		any encode
	) {
		$args(name = "dateSelect", args = arguments);
		arguments.objectName = $objectName(argumentCollection = arguments);
		arguments.$functionName = "dateSelect";
		return $dateOrTimeSelect(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing three `select` form controls for hour, minute, and second based on the supplied objectName and property.
	 *
	 * [section: View Helpers]
	 * [category: Form Object Functions]
	 *
	 * @objectName [see:textField].
	 * @property [see:textField].
	 * @association [see:textField].
	 * @position [see:textField].
	 * @order Use to change the order of or exclude time select tags.
	 * @separator Use to change the character that is displayed between the time select tags.
	 * @minuteStep Pass in 10 to only show minute 10, 20, 30, etc.
	 * @secondStep Pass in 10 to only show seconds 10, 20, 30, etc.
	 * @includeBlank [see:select].
	 * @label [see:dateSelect].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @errorElement [see:textField].
	 * @errorClass [see:textField].
	 * @combine [see:dateTimeSelect].
	 * @twelveHour whether to display the hours in 24 or 12 hour format. 12 hour format has AM/PM drop downs
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function timeSelect(
		any objectName = "",
		string property = "",
		string association,
		string position,
		string order,
		string separator,
		numeric minuteStep,
		numeric secondStep,
		any includeBlank,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		string errorElement,
		string errorClass,
		boolean combine,
		boolean twelveHour,
		any encode
	) {
		$args(name = "timeSelect", args = arguments);
		arguments.objectName = $objectName(argumentCollection = arguments);
		arguments.$functionName = "timeSelect";
		return $dateOrTimeSelect(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing six `select` form controls (three for date selection and the remaining three for time selection) based on the supplied objectName and property.
	 *
	 * [section: View Helpers]
	 * [category: Form Object Functions]
	 *
	 * @objectName The variable name of the object to build the form control for.
	 * @property The name of the property to use in the form control.
	 * @association The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and Wheels will figure it out.
	 * @position The position used when referencing a hasMany relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and Wheels will figure it out.
	 * @dateOrder Use to change the order of or exclude date select tags.
	 * @dateseparator Use to change the character that is displayed between the date select tags.
	 * @startYear First year in select list.
	 * @startYear Last year in select list.
	 * @monthDisplay Pass in names, numbers, or abbreviations to control display.
	 * @timeOrder Use to change the order of or exclude time select tags.
	 * @timeSeparator Use to change the character that is displayed between the time select tags.
	 * @minuteStep Pass in 10 to only show minute 10, 20, 30, etc.
	 * @secondStep Pass in 10 to only show seconds 10, 20, 30, etc
	 * @separator Use to change the character that is displayed between the first and second set of select tags.
	 * @includeBlank Whether to include a blank option in the select form control. Pass true to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -").
	 * @label The label text to use in the form control.
	 * @labelPlacement Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight.
	 * @prepend String to prepend to the form control. Useful to wrap the form control with HTML tags.
	 * @append String to append to the form control. Useful to wrap the form control with HTML tags.
	 * @prependToLabel String to prepend to the form control's label. Useful to wrap the form control with HTML tags.
	 * @appendToLabel String to append to the form control's label. Useful to wrap the form control with HTML tags.
	 * @errorElement HTML tag to wrap the form control with when the object contains errors.
	 * @errorClass The class name of the HTML tag that wraps the form control when there are errors.
	 * @combine Set to false to not combine the select parts into a single DateTime object.
	 * @twelveHour Whether to display the hours in 24 or 12 hour format. 12 hour format has AM/PM drop downs
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function dateTimeSelect(
		required string objectName,
		required string property,
		string association,
		string position,
		string dateOrder,
		string dateSeparator,
		numeric startYear,
		numeric endYear,
		string monthDisplay,
		string monthNames,
		string monthAbbreviations,
		string timeOrder,
		string timeSeparator,
		numeric minuteStep,
		numeric secondStep,
		string separator,
		any includeBlank,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		string errorElement,
		string errorClass,
		boolean combine,
		boolean twelveHour,
		any encode
	) {
		$args(name = "dateTimeSelect", reserved = "name", args = arguments);
		arguments.objectName = $objectName(argumentCollection = arguments);
		arguments.name = $tagName(arguments.objectName, arguments.property);
		arguments.$functionName = "dateTimeSelect";
		return dateTimeSelectTags(argumentCollection = arguments);
	}
}
