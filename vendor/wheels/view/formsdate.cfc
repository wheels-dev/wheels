component {
	/**
	 * Internal function.
	 */
	public string function $yearSelectTag(required numeric startYear, required numeric endYear) {
		if (StructKeyExists(arguments, "value") && Val(arguments.value)) {
			if (arguments.value < arguments.startYear && arguments.endYear > arguments.startYear) {
				arguments.startYear = arguments.value;
			} else if (arguments.value < arguments.endYear && arguments.endYear < arguments.startYear) {
				arguments.endYear = arguments.value;
			}
		}
		arguments.$loopFrom = arguments.startYear;
		arguments.$loopTo = arguments.endYear;
		arguments.$type = "year";
		arguments.$step = 1;
		StructDelete(arguments, "startYear");
		StructDelete(arguments, "endYear");
		return $yearMonthHourMinuteSecondSelectTag(argumentCollection = arguments);
	}

	/**
	 * Internal function.
	 */
	public string function $monthSelectTag(
		required string monthDisplay,
		required string monthNames,
		required string monthAbbreviations
	) {
		arguments.$loopFrom = 1;
		arguments.$loopTo = 12;
		arguments.$type = "month";
		arguments.$step = 1;
		if (arguments.monthDisplay == "names") {
			arguments.$optionNames = arguments.monthNames;
		} else if (arguments.monthDisplay == "abbreviations") {
			arguments.$optionNames = arguments.monthAbbreviations;
		}
		StructDelete(arguments, "monthDisplay");
		StructDelete(arguments, "monthNames");
		StructDelete(arguments, "monthAbbreviations");
		return $yearMonthHourMinuteSecondSelectTag(argumentCollection = arguments);
	}

	/**
	 * Internal function.
	 */
	public string function $daySelectTag() {
		arguments.$loopFrom = 1;
		arguments.$loopTo = 31;
		arguments.$type = "day";
		arguments.$step = 1;
		return $yearMonthHourMinuteSecondSelectTag(argumentCollection = arguments);
	}

	/**
	 * Internal function.
	 */
	public string function $hourSelectTag() {
		arguments.$loopFrom = 0;
		arguments.$loopTo = 23;
		arguments.$type = "hour";
		arguments.$step = 1;
		if (arguments.twelveHour) {
			arguments.$loopFrom = 1;
			arguments.$loopTo = 12;
		}
		return $yearMonthHourMinuteSecondSelectTag(argumentCollection = arguments);
	}

	/**
	 * Internal function.
	 */
	public string function $minuteSelectTag(required numeric minuteStep) {
		arguments.$loopFrom = 0;
		arguments.$loopTo = 59;
		arguments.$type = "minute";
		arguments.$step = arguments.minuteStep;
		StructDelete(arguments, "minuteStep");
		return $yearMonthHourMinuteSecondSelectTag(argumentCollection = arguments);
	}

	/**
	 * Internal function.
	 */
	public any function $secondSelectTag(required numeric secondStep) {
		arguments.$loopFrom = 0;
		arguments.$loopTo = 59;
		arguments.$type = "second";
		arguments.$step = arguments.secondStep;
		StructDelete(arguments, "secondStep");
		return $yearMonthHourMinuteSecondSelectTag(argumentCollection = arguments);
	}

	/**
	 * Internal function.
	 */
	public string function $dateOrTimeSelect(
		required any objectName,
		required string property,
		required string $functionName,
		boolean combine = true,
		boolean twelveHour = false
	) {
		local.combine = arguments.combine;
		StructDelete(arguments, "combine");
		local.name = $tagName(arguments.objectName, arguments.property);
		arguments.$id = $tagId(arguments.objectName, arguments.property);

		// in order to support 12-hour format, we have to enforce some rules
		// if arguments.twelveHour is true, then order MUST contain ampm
		// if the order contains ampm, then arguments.twelveHour MUST be true
		if (ListFindNoCase(arguments.order, "hour") && arguments.twelveHour && !ListFindNoCase(arguments.order, "ampm")) {
			arguments.twelveHour = true;
			if (!ListFindNoCase(arguments.order, "ampm")) {
				arguments.order = ListAppend(arguments.order, "ampm");
			}
		}

		local.value = $formValue(argumentCollection = arguments);
		// Added this section for Adobe Coldfusion as it returns a "java.time.LocalDateTime" object for datetime data
		if(isInstanceOf(local.value,"java.time.LocalDateTime")){
			local.value = createDateTime(local.value.getYear(),local.value.getMonthValue(),local.value.getDayOfMonth(),local.value.getHour(),local.value.getMinute(),local.value.getSecond());
		}
		local.rv = "";
		local.firstDone = false;
		local.iEnd = ListLen(arguments.order);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.order, local.i);
			local.marker = "($" & local.item & ")";
			if (!local.combine) {
				local.name = $tagName(arguments.objectName, "#arguments.property#-#local.item#");
				local.marker = "";
			}
			arguments.name = local.name & local.marker;
			arguments.value = local.value;
			if (IsDate(local.value)) {
				if (arguments.twelveHour && ListFind("hour,ampm", local.item)) {
					if (local.item == "hour") {
						arguments.value = TimeFormat(local.value, 'h');
					} else if (local.item == "ampm") {
						arguments.value = TimeFormat(local.value, 'tt');
					}
				} else {
					arguments.value = $resolveDateTime(local.item, local.value);
				}
			}
			if (local.firstDone) {
				local.rv &= arguments.separator;
			}
			local.functionMap = {
				year: "$yearSelectTag",
				month: "$monthSelectTag",
				day: "$daySelectTag",
				hour: "$hourSelectTag",
				minute: "$minuteSelectTag",
				second: "$secondSelectTag",
				yearMonthHourMinuteSecond: "$yearMonthHourMinuteSecondSelectTag",
				ampm: "$ampmSelectTag"
			};

			if (structKeyExists(functionMap, local.item)) {
				local.rv &= invoke(this, local.functionMap[local.item], arguments);
			} else {
				throw("Invalid item value: " & local.item);
			}
			local.firstDone = true;
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $yearMonthHourMinuteSecondSelectTag(
		required string name,
		required string value,
		required any includeBlank,
		required string label,
		required string labelPlacement,
		required string prepend,
		required string append,
		required string prependToLabel,
		required string appendToLabel,
		string errorElement = "",
		string errorClass = "",
		required string $type,
		required numeric $loopFrom,
		required numeric $loopTo,
		required string $id,
		required numeric $step,
		string $optionNames = "",
		boolean twelveHour = false,
		date $now = Now(),
		any encode = false
	) {
		local.optionContent = "";

		// only set the default value if the value is blank and includeBlank is false
		if (!Len(arguments.value) && (IsBoolean(arguments.includeBlank) && !arguments.includeBlank)) {
			if (arguments.twelveHour && arguments.$type IS "hour") {
				arguments.value = TimeFormat(arguments.$now, 'h');
			} else {
				arguments.value = $resolveDateTime(arguments.$type, arguments.$now);
			}
		}

		if (StructKeyExists(arguments, "order") && ListLen(arguments.order) > 1) {
			if (ListLen(arguments.includeBlank) > 1) {
				arguments.includeBlank = ListGetAt(arguments.includeBlank, ListFindNoCase(arguments.order, arguments.$type));
			}
			if (ListLen(arguments.label) > 1) {
				arguments.label = ListGetAt(arguments.label, ListFindNoCase(arguments.order, arguments.$type));
			}
			if (StructKeyExists(arguments, "labelClass") && ListLen(arguments.labelClass) > 1) {
				arguments.labelClass = ListGetAt(arguments.labelClass, ListFindNoCase(arguments.order, arguments.$type));
			}
		}
		if (!StructKeyExists(arguments, "id")) {
			arguments.id = arguments.$id & "-" & arguments.$type;
		}
		local.before = $formBeforeElement(argumentCollection = arguments);
		local.after = $formAfterElement(argumentCollection = arguments);
		local.content = "";
		if (!IsBoolean(arguments.includeBlank) || arguments.includeBlank) {
			local.args = {};
			local.args.value = "";
			if (!Len(arguments.value)) {
				local.args.selected = "selected";
			}
			if (!IsBoolean(arguments.includeBlank)) {
				local.optionContent = arguments.includeBlank;
			}
			local.content &= $element(
				name = "option",
				content = local.optionContent,
				attributes = local.args,
				encode = arguments.encode
			);
		}
		if (arguments.$loopFrom < arguments.$loopTo) {
			for (local.i = arguments.$loopFrom; local.i <= arguments.$loopTo; local.i = local.i + arguments.$step) {
				local.args = Duplicate(arguments);
				local.args.counter = local.i;
				local.args.optionContent = local.optionContent;
				local.content &= $yearMonthHourMinuteSecondSelectTagContent(argumentCollection = local.args);
			}
		} else {
			for (local.i = arguments.$loopFrom; local.i >= arguments.$loopTo; local.i = local.i - arguments.$step) {
				local.args = Duplicate(arguments);
				local.args.counter = local.i;
				local.args.optionContent = local.optionContent;
				local.content &= $yearMonthHourMinuteSecondSelectTagContent(argumentCollection = local.args);
			}
		}
		local.encode = IsBoolean(arguments.encode) && arguments.encode ? "attributes" : false;
		return local.before & $element(
			name = "select",
			skip = "objectName,property,label,labelPlacement,prepend,append,prependToLabel,appendToLabel,errorElement,errorClass,value,includeBlank,order,separator,startYear,endYear,monthDisplay,monthNames,monthAbbreviations,dateSeparator,dateOrder,timeSeparator,timeOrder,minuteStep,secondStep,association,position,twelveHour,encode",
			skipStartingWith = "label",
			content = local.content,
			attributes = arguments,
			encode = local.encode
		) & local.after;
	}

	/**
	 * Internal function.
	 */
	public string function $yearMonthHourMinuteSecondSelectTagContent() {
		local.args = {};
		local.args.value = arguments.counter;
		if (arguments.value == arguments.counter) {
			local.args.selected = "selected";
		}
		if (Len(arguments.$optionNames)) {
			arguments.optionContent = ListGetAt(arguments.$optionNames, arguments.counter);
		} else {
			arguments.optionContent = arguments.counter;
		}
		if (arguments.$type == "minute" || arguments.$type == "second") {
			arguments.optionContent = NumberFormat(arguments.optionContent, "09");
		}
		return $element(name = "option", content = arguments.optionContent, attributes = local.args, encode = false);
	}

	/**
	 * Internal function.
	 */
	public string function $ampmSelectTag(
		required string name,
		required string value,
		required string $id,
		date $now = Now()
	) {
		local.options = "AM,PM";
		local.optionContent = "";
		if (!Len(arguments.value)) {
			arguments.value = TimeFormat(arguments.$now, "tt");
		}
		if (!StructKeyExists(arguments, "id")) {
			arguments.id = arguments.$id & "-ampm";
		}
		local.content = "";
		local.iEnd = ListLen(local.options);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.option = ListGetAt(local.options, local.i);
			local.args = {};
			local.args.value = local.option;
			if (arguments.value == local.option) {
				local.args.selected = "selected";
			}
			local.content &= $element(
				name = "option",
				content = local.option,
				attributes = local.args,
				encode = arguments.encode
			);
		}
		local.encode = arguments.encode ? "attributes" : false;
		return $element(
			name = "select",
			skip = "objectName,property,label,labelPlacement,prepend,append,prependToLabel,appendToLabel,errorElement,errorClass,value,includeBlank,order,separator,startYear,endYear,monthDisplay,monthNames,monthAbbreviations,dateSeparator,dateOrder,timeSeparator,timeOrder,minuteStep,secondStep,association,position,twelveHour,encode",
			skipStartingWith = "label",
			content = local.content,
			attributes = arguments,
			encode = local.encode
		);
	}

	public numeric function $resolveDateTime(required string dateTimeString, required date dateTimeValue){
		switch(arguments.dateTimeString) {
			case "year":
				return Year(arguments.dateTimeValue);
			case "month":
				return Month(arguments.dateTimeValue);
			case "day":
				return Day(arguments.dateTimeValue);
			case "hour":
				return Hour(arguments.dateTimeValue);
			case "minute":
				return Minute(arguments.dateTimeValue);
			case "second":
				return Second(arguments.dateTimeValue);
			default:
				throw("Invalid type specified: " & arguments.dateTimeString);
		}
	}
}
