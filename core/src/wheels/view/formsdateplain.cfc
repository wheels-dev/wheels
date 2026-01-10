component {
	/**
	 * Builds and returns a string containing three `select` form controls (month, day, and year) based on a name and value.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @selected [see:selectTag].
	 * @order [see:dateSelect].
	 * @separator [see:dateSelect].
	 * @startYear [see:dateSelect].
	 * @endYear [see:dateSelect].
	 * @monthDisplay [see:dateSelect].
	 * @monthNames [see:dateSelect].
	 * @monthAbbreviations [see:dateSelect].
	 * @includeBlank [see:select].
	 * @label [see:dateSelect].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @combine [see:dateTimeSelect].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function dateSelectTags(
		required string name,
		string selected = "",
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
		boolean combine,
		any encode,
		date $now = Now()
	) {
		$args(name = "dateSelectTags", args = arguments);
		arguments.property = arguments.name;
		arguments.objectName = {};
		arguments.objectName[arguments.name] = arguments.selected;
		StructDelete(arguments, "name");
		StructDelete(arguments, "selected");
		arguments.$functionName = "dateSelectTag";
		return $dateOrTimeSelect(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing three `select` form controls for hour, minute, and second based on name.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @selected [see:selectTag].
	 * @order [see:timeSelect].
	 * @separator [see:timeSelect].
	 * @minuteStep [see:timeSelect].
	 * @secondStep [see:timeSelect].
	 * @includeBlank [see:select].
	 * @label [see:dateSelect].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @combine [see:dateTimeSelect].
	 * @twelveHour [see:timeSelect].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function timeSelectTags(
		required string name,
		string selected = "",
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
		boolean combine,
		boolean twelveHour,
		any encode
	) {
		$args(name = "timeSelectTags", args = arguments);
		arguments.property = arguments.name;
		arguments.objectName = {};
		arguments.objectName[arguments.name] = arguments.selected;
		StructDelete(arguments, "name");
		StructDelete(arguments, "selected");
		arguments.$functionName = "timeSelectTag";
		return $dateOrTimeSelect(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing six `select` form controls (three for date selection and the remaining three for time selection) based on a name.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @selected [see:selectTag].
	 * @dateOrder [see:dateTimeSelect].
	 * @dateSeparator [see:dateTimeSelect].
	 * @startYear [see:dateSelect].
	 * @endYear [see:dateSelect].
	 * @monthDisplay [see:dateSelect].
	 * @monthNames [see:dateSelect].
	 * @monthAbbreviations [see:dateSelect].
	 * @timeOrder [see:dateTimeSelect].
	 * @timeSeparator [see:dateTimeSelect].
	 * @minuteStep [see:timeSelect].
	 * @secondStep [see:timeSelect].
	 * @separator [see:dateTimeSelect].
	 * @includeBlank [see:select].
	 * @label [see:dateSelect].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @combine [see:dateTimeSelect].
	 * @twelveHour [see:timeSelect].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function dateTimeSelectTags(
		required string name,
		string selected = "",
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
		boolean combine,
		boolean twelveHour,
		any encode
	) {
		$args(name = "dateTimeSelectTags", args = arguments);
		local.rv = "";
		local.separator = arguments.separator;
		local.label = arguments.label;

		// create date portion
		arguments.order = arguments.dateOrder;
		arguments.separator = arguments.dateSeparator;
		// when a list of 6 elements has been passed in as labels we assume the first 3 are meant to be placed on the date related tags
		if (ListLen(local.label) == 6) {
			arguments.label = ListGetAt(local.label, 1) & "," & ListGetAt(local.label, 2) & "," & ListGetAt(local.label, 3);
		}
		if (StructKeyExists(arguments, "$functionName") && arguments.$functionName == "dateTimeSelect") {
			local.rv &= dateSelect(argumentCollection = arguments);
		} else {
			local.rv &= dateSelectTags(argumentCollection = arguments);
		}

		// separate date and time with a string ("-" by default)
		local.rv &= local.separator;

		// create time portion
		arguments.order = arguments.timeOrder;
		arguments.separator = arguments.timeSeparator;
		// when a list of 6 elements has been passed in as labels we assume the last 3 are meant to be placed on the time related tags
		if (ListLen(local.label) == 6) {
			arguments.label = ListGetAt(local.label, 4) & "," & ListGetAt(local.label, 5) & "," & ListGetAt(local.label, 6);
		}
		if (StructKeyExists(arguments, "$functionName") && arguments.$functionName == "dateTimeSelect") {
			local.rv &= timeSelect(argumentCollection = arguments);
		} else {
			local.rv &= timeSelectTags(argumentCollection = arguments);
		}
		return local.rv;
	}

	/**
	 * Builds and returns a string containing a `select` form control for a range of years based on the supplied name.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @selected The year that should be selected initially.
	 * @startYear [see:dateSelect].
	 * @endYear [see:dateSelect].
	 * @includeBlank [see:select].
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function yearSelectTag(
		required string name,
		string selected = "",
		numeric startYear,
		numeric endYear,
		any includeBlank,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		any encode,
		date $now = Now()
	) {
		$args(name = "yearSelectTag", args = arguments);
		if (IsNumeric(arguments.selected)) {
			arguments.selected = $dateForSelectTags("year", arguments.selected, arguments.$now);
		}
		arguments.order = "year";
		return dateSelectTags(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing a `select` form control for the months of the year based on the supplied name.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @selected The month that should be selected initially.
	 * @monthDisplay [see:dateSelect].
	 * @monthNames [see:dateSelect].
	 * @monthAbbreviations [see:dateSelect].
	 * @includeBlank [see:select].
	 * @label [see:textField].
	 * @labelPlacement around [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function monthSelectTag(
		required string name,
		string selected = "",
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
		any encode,
		date $now = Now()
	) {
		$args(name = "monthSelectTag", args = arguments);
		if (IsNumeric(arguments.selected) && IsValid("range", arguments.selected, 0, 12)) {
			arguments.selected = $dateForSelectTags("month", arguments.selected, arguments.$now);
		}
		arguments.order = "month";
		return dateSelectTags(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing a `select` form control for the days of the week based on the supplied name.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @selected The day that should be selected initially.
	 * @includeBlank [see:select].
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function daySelectTag(
		required string name,
		string selected = "",
		any includeBlank,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		any encode,
		date $now = Now()
	) {
		$args(name = "daySelectTag", args = arguments);
		if (IsNumeric(arguments.selected) && IsValid("range", arguments.selected, 0, 31)) {
			arguments.selected = $dateForSelectTags("day", arguments.selected, arguments.$now);
		}
		arguments.order = "day";
		return dateSelectTags(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing one `select` form control for the hours of the day based on the supplied name.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @selected The day that should be selected initially.
	 * @includeBlank [see:select].
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @twelveHour [see:timeSelect].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function hourSelectTag(
		required string name,
		string selected = "",
		any includeBlank,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		boolean twelveHour,
		any encode,
		date $now = Now()
	) {
		$args(name = "hourSelectTag", args = arguments);
		if (IsNumeric(arguments.selected) && arguments.selected >= 0 && arguments.selected < 60) {
			arguments.selected = CreateTime(arguments.selected, Minute(arguments.$now), Second(arguments.$now));
		}
		arguments.order = "hour";
		return timeSelectTags(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing one `select` form control for the minutes of an hour based on the supplied name.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @selected The day that should be selected initially.
	 * @minuteStep [see:timeSelect].
	 * @includeBlank [see:select].
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function minuteSelectTag(
		required string name,
		string selected = "",
		numeric minuteStep,
		any includeBlank,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		any encode,
		date $now = Now()
	) {
		$args(name = "minuteSelectTag", args = arguments);
		if (IsNumeric(arguments.selected) && arguments.selected >= 0 && arguments.selected < 60) {
			arguments.selected = CreateTime(Hour(arguments.$now), arguments.selected, Second(arguments.$now));
		}
		arguments.order = "minute";
		return timeSelectTags(argumentCollection = arguments);
	}

	/**
	 * Builds and returns a string containing one `select` form control for the seconds of a minute based on the supplied name.
	 *
	 * [section: View Helpers]
	 * [category: Form Tag Functions]
	 *
	 * @name [see:textFieldTag].
	 * @selected The day that should be selected initially.
	 * @secondStep [see:timeSelect].
	 * @includeBlank [see:select].
	 * @label [see:textField].
	 * @labelPlacement [see:textField].
	 * @prepend [see:textField].
	 * @append [see:textField].
	 * @prependToLabel [see:textField].
	 * @appendToLabel [see:textField].
	 * @encode [see:styleSheetLinkTag].
	 */
	public string function secondSelectTag(
		required string name,
		string selected = "",
		numeric secondStep,
		any includeBlank,
		string label,
		string labelPlacement,
		string prepend,
		string append,
		string prependToLabel,
		string appendToLabel,
		any encode,
		date $now = Now()
	) {
		$args(name = "secondSelectTag", args = arguments);
		if (IsNumeric(arguments.selected) && arguments.selected >= 0 && arguments.selected < 60) {
			arguments.selected = CreateTime(Hour(arguments.$now), Minute(arguments.$now), arguments.selected);
		}
		arguments.order = "second";
		return timeSelectTags(argumentCollection = arguments);
	}

	/**
	 * Internal function.
	 */
	public date function $dateForSelectTags(required string part, required numeric value, required date $now) {
		local.year = Year(arguments.$now);
		local.month = Month(arguments.$now);
		local.day = Day(arguments.$now);
		local.rv = arguments.$now;
		switch (arguments.part) {
			case "year":
				local.year = arguments.value;
				break;
			case "month":
				local.month = arguments.value;
				break;
			case "day":
				local.day = arguments.value;
				break;
		}

		// Handle February.
		if (local.month == 2 && ((!IsLeapYear(local.year) && local.day > 29) || (IsLeapYear(local.year) && local.day > 28))) {
			if (IsLeapYear(local.year)) {
				local.day = 29;
			} else {
				local.day = 28;
			}
		}

		try {
			local.rv = CreateDate(local.year, local.month, local.day);
		} catch (any e) {
			local.rv = arguments.$now;
		}
		return local.rv;
	}
}
