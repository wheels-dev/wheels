<cfscript>
		// Function defaults.
		application.$wheels.functions = {};
		application.$wheels.functions.autoLink = {link = "all", encode = true};
		application.$wheels.functions.average = {distinct = false, parameterize = true, ifNull = ""};
		application.$wheels.functions.belongsTo = {joinType = "inner"};
		application.$wheels.functions.buttonTo = {
			onlyPath = true,
			host = "",
			protocol = "",
			port = 0,
			text = "",
			image = "",
			encode = true
		};
		application.$wheels.functions.buttonTag = {
			type = "submit",
			value = "save",
			content = "Save changes",
			image = "",
			prepend = "",
			append = "",
			encode = true
		};
		application.$wheels.functions.caches = {time = 60, static = false};
		application.$wheels.functions.checkBox = {
			label = "useDefaultLabel",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			errorElement = "span",
			errorClass = "field-with-errors",
			checkedValue = 1,
			unCheckedValue = 0,
			encode = true
		};
		application.$wheels.functions.checkBoxTag = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			value = 1,
			encode = true
		};
		application.$wheels.functions.count = {parameterize = true};
		application.$wheels.functions.csrfMetaTags = {encode = true};
		application.$wheels.functions.create = {parameterize = true, reload = false};
		application.$wheels.functions.dateSelect = {
			label = false,
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			errorElement = "span",
			errorClass = "field-with-errors",
			includeBlank = false,
			order = "month,day,year",
			separator = " ",
			startYear = Year(Now()) - 5,
			endYear = Year(Now()) + 5,
			monthDisplay = "names",
			monthNames = "January,February,March,April,May,June,July,August,September,October,November,December",
			monthAbbreviations = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec",
			encode = true
		};
		application.$wheels.functions.dateSelectTags = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			includeBlank = false,
			order = "month,day,year",
			separator = " ",
			startYear = Year(Now()) - 5,
			endYear = Year(Now()) + 5,
			monthDisplay = "names",
			monthNames = "January,February,March,April,May,June,July,August,September,October,November,December",
			monthAbbreviations = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec",
			encode = true
		};
		application.$wheels.functions.dateTimeSelect = {
			label = false,
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			errorElement = "span",
			errorClass = "field-with-errors",
			includeBlank = false,
			dateOrder = "month,day,year",
			dateSeparator = " ",
			startYear = Year(Now()) - 5,
			endYear = Year(Now()) + 5,
			monthDisplay = "names",
			monthNames = "January,February,March,April,May,June,July,August,September,October,November,December",
			monthAbbreviations = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec",
			timeOrder = "hour,minute,second",
			timeSeparator = ":",
			minuteStep = 1,
			secondStep = 1,
			separator = " - ",
			twelveHour = false,
			encode = true
		};
		application.$wheels.functions.dateTimeSelectTags = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			includeBlank = false,
			dateOrder = "month,day,year",
			dateSeparator = " ",
			startYear = Year(Now()) - 5,
			endYear = Year(Now()) + 5,
			monthDisplay = "names",
			monthNames = "January,February,March,April,May,June,July,August,September,October,November,December",
			monthAbbreviations = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec",
			timeOrder = "hour,minute,second",
			timeSeparator = ":",
			minuteStep = 1,
			secondStep = 1,
			separator = " - ",
			twelveHour = false,
			encode = true
		};
		application.$wheels.functions.daySelectTag = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			includeBlank = false,
			encode = true
		};
		application.$wheels.functions.delete = {parameterize = true};
		application.$wheels.functions.deleteAll = {reload = false, parameterize = true, instantiate = false};
		application.$wheels.functions.deleteByKey = {reload = false};
		application.$wheels.functions.deleteOne = {reload = false};
		application.$wheels.functions.distanceOfTimeInWords = {includeSeconds = false};
		application.$wheels.functions.endFormTag = {prepend = "", append = "", encode = true};
		application.$wheels.functions.errorMessageOn = {
			prependText = "",
			appendText = "",
			wrapperElement = "span",
			class = "error-message",
			encode = true
		};
		application.$wheels.functions.errorMessagesFor = {
			class = "error-messages",
			showDuplicates = true,
			encode = true,
			includeAssociations = true
		};
		application.$wheels.functions.excerpt = {radius = 100, excerptString = "..."};
		application.$wheels.functions.exists = {reload = false, parameterize = true};
		application.$wheels.functions.fileField = {
			label = "useDefaultLabel",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			errorElement = "span",
			errorClass = "field-with-errors",
			encode = true
		};
		application.$wheels.functions.fileFieldTag = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			encode = true
		};
		application.$wheels.functions.findAll = {
			reload = false,
			parameterize = true,
			perPage = 10,
			order = "",
			group = "",
			returnAs = "query",
			returnIncluded = true
		};
		application.$wheels.functions.findByKey = {reload = false, parameterize = true, returnAs = "object"};
		application.$wheels.functions.findOne = {reload = false, parameterize = true, returnAs = "object"};
		application.$wheels.functions.flashKeep = {};
		application.$wheels.functions.flashMessages = {
			class = "flash-messages",
			includeEmptyContainer = "false",
			encode = true
		};
		application.$wheels.functions.hasMany = {joinType = "outer", dependent = false};
		application.$wheels.functions.hasManyCheckBox = {encode = true};
		application.$wheels.functions.hasManyRadioButton = {encode = true};
		application.$wheels.functions.hasOne = {joinType = "outer", dependent = false};
		application.$wheels.functions.hiddenField = {encode = true};
		application.$wheels.functions.hiddenFieldTag = {encode = true};
		application.$wheels.functions.highlight = {delimiter = ",", tag = "span", class = "highlight", encode = true};
		application.$wheels.functions.hourSelectTag = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			includeBlank = false,
			twelveHour = false,
			encode = true
		};
		application.$wheels.functions.imageTag = {onlyPath = true, host = "", protocol = "", port = 0, encode = true};
		application.$wheels.functions.includePartial = {layout = "", spacer = "", dataFunction = true};
		application.$wheels.functions.javaScriptIncludeTag = {type = "text/javascript", head = false, encode = true};
		application.$wheels.functions.linkTo = {onlyPath = true, host = "", protocol = "", port = 0, encode = true};
		application.$wheels.functions.mailTo = {encode = true};
		application.$wheels.functions.maximum = {parameterize = true, ifNull = ""};
		application.$wheels.functions.minimum = {parameterize = true, ifNull = ""};
		application.$wheels.functions.minuteSelectTag = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			includeBlank = false,
			minuteStep = 1,
			encode = true
		};
		application.$wheels.functions.monthSelectTag = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			includeBlank = false,
			monthDisplay = "names",
			monthNames = "January,February,March,April,May,June,July,August,September,October,November,December",
			monthAbbreviations = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec",
			encode = true
		};
		application.$wheels.functions.nestedProperties = {
			autoSave = true,
			allowDelete = false,
			sortProperty = "",
			rejectIfBlank = ""
		};
		application.$wheels.functions.paginationLinks = {
			windowSize = 2,
			alwaysShowAnchors = true,
			anchorDivider = " ... ",
			linkToCurrentPage = false,
			prepend = "",
			append = "",
			prependToPage = "",
			addActiveClassToPrependedParent = false,
			prependOnFirst = true,
			prependOnAnchor = true,
			appendToPage = "",
			appendOnLast = true,
			appendOnAnchor = true,
			classForCurrent = "",
			name = "page",
			showSinglePage = false,
			pageNumberAsParam = true,
			encode = true
		};
		application.$wheels.functions.passwordField = {
			label = "useDefaultLabel",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			errorElement = "span",
			errorClass = "field-with-errors",
			encode = true
		};
		application.$wheels.functions.passwordFieldTag = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			encode = true
		};
		application.$wheels.functions.processRequest = {method = "get", returnAs = "", rollback = false};
		application.$wheels.functions.protectsFromForgery = {with = "exception", only = "", except = ""};
		application.$wheels.functions.radioButton = {
			label = "useDefaultLabel",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			errorElement = "span",
			errorClass = "field-with-errors",
			encode = true
		};
		application.$wheels.functions.radioButtonTag = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			encode = true
		};
		application.$wheels.functions.redirectTo = {
			onlyPath = true,
			host = "",
			protocol = "",
			port = 0,
			addToken = false,
			statusCode = 302,
			delay = false,
			encode = true
		};
		application.$wheels.functions.renderView = {layout = ""};
		application.$wheels.functions.renderWith = {layout = ""};
		application.$wheels.functions.renderPartial = {layout = "", dataFunction = true};
		application.$wheels.functions.save = {parameterize = true, reload = false};
		application.$wheels.functions.secondSelectTag = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			includeBlank = false,
			secondStep = 1,
			encode = true
		};
		application.$wheels.functions.select = {
			label = "useDefaultLabel",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			errorElement = "span",
			errorClass = "field-with-errors",
			includeBlank = false,
			valueField = "",
			textField = "",
			encode = true
		};
		application.$wheels.functions.selectTag = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			includeBlank = false,
			multiple = false,
			valueField = "",
			textField = "",
			encode = true
		};
		application.$wheels.functions.sendEmail = {
			layout = false,
			detectMultipart = true,
			from = "",
			to = "",
			subject = "",
			deliver = true
		};
		application.$wheels.functions.sendFile = {disposition = "attachment", deliver = true};
		application.$wheels.functions.simpleFormat = {wrap = true, encode = true};
		application.$wheels.functions.startFormTag = {
			onlyPath = true,
			host = "",
			protocol = "",
			port = 0,
			method = "post",
			multipart = false,
			prepend = "",
			append = "",
			encode = true
		};
		application.$wheels.functions.stripLinks = {encode = true};
		application.$wheels.functions.stripTags = {encode = true};
		application.$wheels.functions.styleSheetLinkTag = {type = "text/css", media = "all", head = false, encode = true};
		application.$wheels.functions.submitTag = {
			value = "Save changes",
			image = "",
			prepend = "",
			append = "",
			encode = true
		};
		application.$wheels.functions.sum = {distinct = false, parameterize = true, ifNull = ""};
		application.$wheels.functions.textArea = {
			label = "useDefaultLabel",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			errorElement = "span",
			errorClass = "field-with-errors",
			encode = true
		};
		application.$wheels.functions.textAreaTag = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			encode = true
		};
		application.$wheels.functions.textField = {
			label = "useDefaultLabel",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			errorElement = "span",
			errorClass = "field-with-errors",
			encode = true
		};
		application.$wheels.functions.textFieldTag = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			encode = true
		};
		application.$wheels.functions.timeAgoInWords = {includeSeconds = false};
		application.$wheels.functions.timeSelect = {
			label = false,
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			errorElement = "span",
			errorClass = "field-with-errors",
			includeBlank = false,
			order = "hour,minute,second",
			separator = ":",
			minuteStep = 1,
			secondStep = 1,
			twelveHour = false,
			encode = true
		};
		application.$wheels.functions.timeSelectTags = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			includeBlank = false,
			order = "hour,minute,second",
			separator = ":",
			minuteStep = 1,
			secondStep = 1,
			twelveHour = false,
			encode = true
		};
		application.$wheels.functions.timeUntilInWords = {includeSeconds = false};
		application.$wheels.functions.toggle = {save = true};
		application.$wheels.functions.truncate = {length = 30, truncateString = "..."};
		application.$wheels.functions.update = {parameterize = true, reload = false};
		application.$wheels.functions.updateAll = {reload = false, parameterize = true, instantiate = false};
		application.$wheels.functions.updateByKey = {reload = false};
		application.$wheels.functions.updateOne = {reload = false};
		application.$wheels.functions.updateProperty = {parameterize = true};
		application.$wheels.functions.URLFor = {onlyPath = true, host = "", protocol = "", port = 0, encode = true};
		application.$wheels.functions.validatesConfirmationOf = {message = "[property] should match confirmation"};
		application.$wheels.functions.validatesExclusionOf = {message = "[property] is reserved", allowBlank = false};
		application.$wheels.functions.validatesFormatOf = {message = "[property] is invalid", allowBlank = false};
		application.$wheels.functions.validatesInclusionOf = {
			message = "[property] is not included in the list",
			allowBlank = false
		};
		application.$wheels.functions.validatesLengthOf = {
			message = "[property] is the wrong length",
			allowBlank = false,
			exactly = 0,
			maximum = 0,
			minimum = 0,
			within = ""
		};
		application.$wheels.functions.validatesNumericalityOf = {
			message = "[property] is not a number",
			allowBlank = false,
			onlyInteger = false,
			odd = "",
			even = "",
			greaterThan = "",
			greaterThanOrEqualTo = "",
			equalTo = "",
			lessThan = "",
			lessThanOrEqualTo = ""
		};
		application.$wheels.functions.validatesPresenceOf = {message = "[property] can't be empty"};
		application.$wheels.functions.validatesUniquenessOf = {
			message = "[property] has already been taken",
			allowBlank = false
		};
		application.$wheels.functions.verifies = {handler = ""};
		application.$wheels.functions.wordTruncate = {length = 5, truncateString = "..."};
		application.$wheels.functions.yearSelectTag = {
			label = "",
			labelPlacement = "around",
			prepend = "",
			append = "",
			prependToLabel = "",
			appendToLabel = "",
			includeBlank = false,
			startYear = Year(Now()) - 5,
			endYear = Year(Now()) + 5,
			encode = true
		};
</cfscript>
