component {

	property name="Mixins" inject="id:Plugins";

	public void function $init(struct keys = {}) {

		// Embedding values from `Application.cfc`'s `this` scope into the current component's `this` scope.
		for (key in keys) {
			application[key] = keys[key];
		}

		// Abort if called from incorrect file.
		application.wo.$abortInvalidRequest();

		// Setup the CFWheels storage struct for the current request.
		application.wo.$initializeRequestScope();

		if (StructKeyExists(application, "wheels")) {
			// Set or reset all settings but make sure to pass along the reload password between forced reloads with "reload=x".
			if (StructKeyExists(application.wheels, "reloadPassword")) {
				local.oldReloadPassword = application.wheels.reloadPassword;
			}
			// Check old environment for environment switch
			if (StructKeyExists(application.wheels, "allowEnvironmentSwitchViaUrl")) {
				local.allowEnvironmentSwitchViaUrl = application.wheels.allowEnvironmentSwitchViaUrl;
				local.oldEnvironment = application.wheels.environment;
			}
		}

		application.$wheels = {};
		if (StructKeyExists(local, "oldReloadPassword")) {
			application.$wheels.reloadPassword = local.oldReloadPassword;
		}


		// Check and store server engine name, throw error if using a version that we don't support.
		if (StructKeyExists(server, "lucee")) {
			application.$wheels.serverName = "Lucee";
			application.$wheels.serverVersion = server.lucee.version;
		} else {
			application.$wheels.serverName = "Adobe ColdFusion";
			application.$wheels.serverVersion = server.coldfusion.productVersion;
		}
		application.$wheels.serverVersionMajor = ListFirst(application.$wheels.serverVersion, ".,");

		local.upgradeTo = application.wo.$checkMinimumVersion(
			engine = application.$wheels.serverName,
			version = application.$wheels.serverVersion
		);
		if (
			Len(local.upgradeTo)
			&& !StructKeyExists(application, "disableEngineCheck")
			&& !StructKeyExists(url, "disableEngineCheck")
		) {
			local.type = "Wheels.EngineNotSupported";
			local.message = "#application.$wheels.serverName# #application.$wheels.serverVersion# is not supported by CFWheels.";
			if (IsBoolean(local.upgradeTo)) {
				Throw(type = local.type, message = local.message, extendedInfo = "Please use Lucee or Adobe ColdFusion instead.");
			} else {
				Throw(
					type = local.type,
					message = local.message,
					extendedInfo = "Please upgrade to version #local.upgradeTo# or higher."
				);
			}
		}

		// Copy over the CGI variables we need to the request scope.
		// Since we use some of these to determine URL rewrite capabilities we need to be able to access them directly on application start for example.
		request.cgi = application.wo.$cgiScope();

		// Set up containers for routes, caches, settings etc.
		// TODO remove the static version number
		application.$wheels.version = "3.0.0";
		try {
			application.$wheels.hostName = CreateObject("java", "java.net.InetAddress").getLocalHost().getHostName();
		} catch (any e) {
		}
		application.$wheels.controllers = {};
		application.$wheels.models = {};
		application.$wheels.existingHelperFiles = "";
		application.$wheels.existingLayoutFiles = "";
		application.$wheels.existingObjectFiles = "";
		application.$wheels.nonExistingHelperFiles = "";
		application.$wheels.nonExistingLayoutFiles = "";
		application.$wheels.nonExistingObjectFiles = "";
		application.$wheels.directoryFiles = {};
		application.$wheels.routes = [];
		application.$wheels.resourceControllerNaming = "plural";
		application.$wheels.namedRoutePositions = {};
		application.$wheels.mixins = {};
		application.$wheels.cache = {};
		application.$wheels.cache.sql = {};
		application.$wheels.cache.image = {};
		application.$wheels.cache.main = {};
		application.$wheels.cache.action = {};
		application.$wheels.cache.page = {};
		application.$wheels.cache.partial = {};
		application.$wheels.cache.query = {};
		application.$wheels.cacheLastCulledAt = Now();

		// Set up paths to various folders in the framework.
		application.$wheels.webPath = Replace(
			request.cgi.script_name,
			Reverse(SpanExcluding(Reverse(request.cgi.script_name), "/")),
			""
		);
		application.$wheels.rootPath = "/" & ListChangeDelims(application.$wheels.webPath, "/", "/");
		application.$wheels.rootcomponentPath = ListChangeDelims(application.$wheels.webPath, ".", "/");
		application.$wheels.wheelsComponentPath = ListAppend(application.$wheels.rootcomponentPath, "wheels", ".");

		// Check old environment to see whether we're allowed to switch configuration
		application.$wheels.allowEnvironmentSwitchViaUrl = true;
		if (StructKeyExists(local, "allowEnvironmentSwitchViaUrl") && !local.allowEnvironmentSwitchViaUrl) {
			application.$wheels.allowEnvironmentSwitchViaUrl = false;
		}

		// Set environment either from the url or the developer's environment.cfm file.
		if (
			StructKeyExists(URL, "reload")
			&& !IsBoolean(URL.reload)
			&& Len(url.reload)
			&& StructKeyExists(application.$wheels, "reloadPassword")
			&& (
				!Len(application.$wheels.reloadPassword)
				|| (StructKeyExists(URL, "password") && URL.password == application.$wheels.reloadPassword)
			)
		) {
			application.$wheels.environment = URL.reload;
		} else {
			application.wo.$include(template = "/app/config/environment.cfm");
		}

		// If we're not allowed to switch, override and replace with the old environment
		if (!application.$wheels.allowEnvironmentSwitchViaUrl && StructKeyExists(local, "oldEnvironment")) {
			application.$wheels.environment = local.oldEnvironment;
		}

		// Rewrite settings based on web server rewrite capabilites.
		application.$wheels.rewriteFile = "index.cfm";
		if (Right(request.cgi.script_name, 12) == "/" & application.$wheels.rewriteFile) {
			application.$wheels.URLRewriting = "On";
		} else if (Len(request.cgi.path_info)) {
			application.$wheels.URLRewriting = "Partial";
		} else {
			application.$wheels.URLRewriting = "Off";
		}

		// Set datasource name to same as the folder the app resides in unless the developer has set it with the global setting already.
		if (StructKeyExists(application, "dataSource")) {
			application.$wheels.dataSourceName = application.dataSource;
		} else {
			application.$wheels.dataSourceName = LCase(
				ListLast(GetDirectoryFromPath(GetBaseTemplatePath()), Right(GetDirectoryFromPath(GetBaseTemplatePath()), 1))
			);
		}

		// Set the coreTestDatasourceName to the application dataSourceName if it doesn't exits
		if (!StructKeyExists(application.$wheels, "coreTestDataSourceName")) {
			application.$wheels.coreTestDataSourceName = application.$wheels.dataSourceName;
		}

		application.$wheels.dataSourceUserName = "";
		application.$wheels.dataSourcePassword = "";
		application.$wheels.transactionMode = "commit";

		// Enable or disable major components
		application.$wheels.enablePluginsComponent = true;
		application.$wheels.enableMigratorComponent = true;
		application.$wheels.enablePublicComponent = false;
		if (application.$wheels.environment == "development") {
			application.$wheels.enablePublicComponent = true;
		}

		// Create migrations object and set default settings.
		application.$wheels.autoMigrateDatabase = false;
		application.$wheels.migratorTableName = "migratorversions";
		application.$wheels.createMigratorTable = true;
		application.$wheels.writeMigratorSQLFiles = false;
		application.$wheels.migratorObjectCase = "lower";
		application.$wheels.allowMigrationDown = false;
		if (application.$wheels.environment == "development") {
			application.$wheels.allowMigrationDown = true;
		}

		// Cache settings that are always turned on regardless of mode setting.
		application.$wheels.cacheControllerConfig = true;
		application.$wheels.cacheDatabaseSchema = true;
		application.$wheels.cacheModelConfig = true;
		application.$wheels.cachePlugins = true;
		application.$wheels.cacheFileChecking = true;

		// Cache settings that are turned off in development mode only.
		application.$wheels.cacheActions = false;
		application.$wheels.cacheImages = false;
		application.$wheels.cachePages = false;
		application.$wheels.cachePartials = false;
		application.$wheels.cacheQueries = false;
		if (application.$wheels.environment != "development") {
			application.$wheels.cacheActions = true;
			application.$wheels.cacheImages = true;
			application.$wheels.cachePages = true;
			application.$wheels.cachePartials = true;
			application.$wheels.cacheQueries = true;
		}

		// Other caching settings.
		application.$wheels.maximumItemsToCache = 5000;
		application.$wheels.cacheCullPercentage = 10;
		application.$wheels.cacheCullInterval = 5;
		application.$wheels.cacheDatePart = "n";
		application.$wheels.defaultCacheTime = 60;
		application.$wheels.clearQueryCacheOnReload = true;
		application.$wheels.clearTemplateCacheOnReload = true;
		application.$wheels.cacheQueriesDuringRequest = true;

		// CSRF protection settings.
		application.$wheels.csrfStore = "session";
		application.$wheels.csrfCookieEncryptionAlgorithm = "AES";
		application.$wheels.csrfCookieEncryptionSecretKey = "";
		application.$wheels.csrfCookieEncryptionEncoding = "Base64";
		application.$wheels.csrfCookieName = "_wheels_authenticity";
		application.$wheels.csrfCookieDomain = "";
		application.$wheels.csrfCookieEncodeValue = "";
		application.$wheels.csrfCookieHttpOnly = "";
		application.$wheels.csrfCookiePath = "/";
		application.$wheels.csrfCookiePreserveCase = "";
		application.$wheels.csrfCookieSecure = "";

		// CORS (Cross-Origin Resource Sharing) settings.
		application.$wheels.allowCorsRequests = false;
		application.$wheels.accessControlAllowOrigin = "*";
		application.$wheels.accessControlAllowMethods = "GET, POST, PATCH, PUT, DELETE, OPTIONS";
		application.$wheels.accessControlAllowMethodsByRoute = false;
		application.$wheels.accessControlAllowCredentials = false;
		application.$wheels.accessControlAllowHeaders = "Origin, Content-Type, X-Auth-Token, X-Requested-By, X-Requested-With";

		// Debugging and error settings.
		application.$wheels.showDebugInformation = true;
		application.$wheels.showErrorInformation = true;
		application.$wheels.sendEmailOnError = false;
		application.$wheels.errorEmailSubject = "Error";
		application.$wheels.excludeFromErrorEmail = "";
		application.$wheels.errorEmailToAddress = "";
		application.$wheels.errorEmailFromAddress = "";
		application.$wheels.includeErrorInEmailSubject = true;
		if (Find(".", request.cgi.server_name)) {
			application.$wheels.errorEmailAddress = "webmaster@"
			& Reverse(ListGetAt(Reverse(request.cgi.server_name), 2, "."))
			& "."
			& Reverse(ListGetAt(Reverse(request.cgi.server_name), 1, "."));
		} else {
			application.$wheels.errorEmailAddress = "";
		}
		if (application.$wheels.environment == "production") {
			application.$wheels.showErrorInformation = false;
			application.$wheels.sendEmailOnError = true;
		}
		if (application.$wheels.environment != "development") {
			application.$wheels.showDebugInformation = false;
		}

		// Asset path settings.
		// assetPaths can be struct with two keys, http and https, if no https struct key, http is used for secure and non-secure.
		// Example: {http="asset0.domain1.com,asset2.domain1.com,asset3.domain1.com", https="secure.domain1.com"}
		application.$wheels.assetQueryString = false;
		application.$wheels.assetPaths = false;
		if (application.$wheels.environment != "development") {
			application.$wheels.assetQueryString = true;
		}

		// Configurable paths.
		application.$wheels.eventPath = "/app/events";
		application.$wheels.filePath = "files";
		application.$wheels.imagePath = "images";
		application.$wheels.javascriptPath = "javascripts";
		application.$wheels.modelPath = "/app/models";
		application.$wheels.pluginPath = "/app/plugins";
		application.$wheels.pluginComponentPath = "/app/plugins";
		application.$wheels.stylesheetPath = "stylesheets";
		application.$wheels.viewPath = "/app/views";
		application.$wheels.controllerPath = "/app/controllers";

		// Test framework settings.
		application.$wheels.validateTestPackageMetaData = true;
		application.$wheels.restoreTestRunnerApplicationScope = true;

		// Miscellaneous settings.
		application.$wheels.encodeURLs = true;
		application.$wheels.encodeHtmlTags = true;
		application.$wheels.encodeHtmlAttributes = true;
		application.$wheels.uncountables = "advice,air,blood,deer,equipment,fish,food,furniture,garbage,graffiti,grass,homework,housework,information,knowledge,luggage,mathematics,meat,milk,money,music,pollution,research,rice,sand,series,sheep,soap,software,species,sugar,traffic,transportation,travel,trash,water,feedback";
		application.$wheels.irregulars = {
			child = "children",
			foot = "feet",
			man = "men",
			move = "moves",
			person = "people",
			sex = "sexes",
			tooth = "teeth",
			woman = "women"
		};
		application.$wheels.tableNamePrefix = "";
		application.$wheels.obfuscateURLs = false;
		application.$wheels.reloadPassword = "";
		application.$wheels.redirectAfterReload = false;
		application.$wheels.softDeleteProperty = "deletedAt";
		application.$wheels.timeStampOnCreateProperty = "createdAt";
		application.$wheels.timeStampOnUpdateProperty = "updatedAt";
		application.$wheels.timeStampMode = "utc";
		application.$wheels.ipExceptions = "";
		application.$wheels.overwritePlugins = true;
		application.$wheels.deletePluginDirectories = true;
		application.$wheels.loadIncompatiblePlugins = true;
		application.$wheels.automaticValidations = true;
		application.$wheels.setUpdatedAtOnCreate = true;
		application.$wheels.useExpandedColumnAliases = false;
		application.$wheels.lowerCaseTableNames = false;
		application.$wheels.modelRequireConfig = false;
		application.$wheels.showIncompatiblePlugins = true;
		application.$wheels.booleanAttributes = "allowfullscreen,async,autofocus,autoplay,checked,compact,controls,declare,default,defaultchecked,defaultmuted,defaultselected,defer,disabled,draggable,enabled,formnovalidate,hidden,indeterminate,inert,ismap,itemscope,loop,multiple,muted,nohref,noresize,noshade,novalidate,nowrap,open,pauseonexit,readonly,required,reversed,scoped,seamless,selected,sortable,spellcheck,translate,truespeed,typemustmatch,visible";
		if (ListFindNoCase("production,maintenance", application.$wheels.environment)) {
			application.$wheels.redirectAfterReload = true;
		}
		application.$wheels.resetPropertiesStructKeyCase = true;

		// If session management is enabled in the application we default to storing Flash data in the session scope, if not we use a cookie.
		if (StructKeyExists(application, "sessionManagement") && application.sessionManagement) {
			application.$wheels.sessionManagement = true;
			application.$wheels.flashStorage = "session";
		} else {
			application.$wheels.sessionManagement = false;
			application.$wheels.flashStorage = "cookie";
		}

		// Additional configurable flash options
		application.$wheels.flashAppend = false;

		// Possible formats for provides functionality.
		application.$wheels.formats = {};
		application.$wheels.formats.html = "text/html";
		application.$wheels.formats.xml = "text/xml";
		application.$wheels.formats.json = "application/json";
		application.$wheels.formats.csv = "text/csv";
		application.$wheels.formats.pdf = "application/pdf";
		application.$wheels.formats.xls = "application/vnd.ms-excel";

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

		// Mime types.
		application.$wheels.mimetypes = {
			txt = "text/plain",
			gif = "image/gif",
			jpg = "image/jpg",
			jpeg = "image/jpg",
			pjpeg = "image/jpg",
			png = "image/png",
			wav = "audio/wav",
			mp3 = "audio/mpeg3",
			pdf = "application/pdf",
			zip = "application/zip",
			ppt = "application/powerpoint",
			pptx = "application/powerpoint",
			doc = "application/word",
			docx = "application/word",
			xls = "application/excel",
			xlsx = "application/excel"
		};

		// Set a flag to indicate that all settings have been loaded.
		application.$wheels.initialized = true;

		// Load general developer settings first, then override with environment specific ones.
		application.wo.$include(template = "/app/config/settings.cfm");
		if (FileExists(ExpandPath("/app/config/#application.$wheels.environment#/settings.cfm"))) {
			application.wo.$include(template = "/app/config/#application.$wheels.environment#/settings.cfm");
		}

		// Clear query (cfquery) and page (cfcache) caches.
		if (application.$wheels.clearQueryCacheOnReload or !StructKeyExists(application.$wheels, "cacheKey")) {
			application.$wheels.cacheKey = Hash(CreateUUID());
		}
		if (application.$wheels.clearTemplateCacheOnReload) {
			application.wo.$cache(action = "flush");
		}

		// Add all public controller / view methods to a list of methods that you should not be allowed to call as a controller action from the url.
		local.allowedGlobalMethods = "get,set,mapper";
		// local.protectedControllerMethods = StructKeyList(
		// 	application.wo.$createObjectFromRoot(path = "wheels", fileName = "Controller", method = "$initControllerClass")
		// );
		application.$wheels.protectedControllerMethods = "";
		// local.iEnd = ListLen(local.protectedControllerMethods);
		// for (local.i = 1; local.i <= local.iEnd; local.i++) {
		// 	local.method = ListGetAt(local.protectedControllerMethods, local.i);
		// 	if (Left(local.method, 1) != "$" && !ListFindNoCase(local.allowedGlobalMethods, local.method)) {
		// 		application.$wheels.protectedControllerMethods = ListAppend(
		// 			application.$wheels.protectedControllerMethods,
		// 			local.method
		// 		);
		// 	}
		// }

		// Enable the main GUI Component
		if (application.$wheels.enablePublicComponent) {
			application.$wheels.public = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Public", method = "$init");
		}

		// Reload the plugins each time we reload the application.
		if (application.$wheels.enablePluginsComponent) {
			application.wo.$loadPlugins();
		}

		// Allow developers to inject plugins into the application variables scope.
		if (!StructIsEmpty(application.$wheels.mixins)) {
			Mixins.$initializeMixins(variables);
		}

		// Create the mapper that will handle creating routes.
		// Needs to be before $loadRoutes and after $loadPlugins.
		application.$wheels.mapper = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Mapper", method = "$init");

		// Load developer routes and adds the default CFWheels routes (unless the developer has specified not to).
		application.wo.$loadRoutes();

		// Create the dispatcher that will handle all incoming requests.
		application.$wheels.dispatch = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Dispatch", method = "$init");

		// Assign it all to the application scope in one atomic call.
		application.wheels = application.$wheels;
		StructDelete(application, "$wheels");

		// Enable the migrator component
		if (application.wheels.enableMigratorComponent) {
			application.wheels.migrator = application.wo.$createObjectFromRoot(path = "wheels", fileName = "Migrator", method = "init");
		}

		// Run the developer's on application start code.
		application.wo.$include(template = "#application.wheels.eventPath#/onapplicationstart.cfm");

		// Auto Migrate Database if requested
		if (application.wheels.enableMigratorComponent && application.wheels.autoMigrateDatabase) {
			application.wheels.migrator.migrateToLatest();
		}

		// Redirect away from reloads on GET requests.
		if (application.wheels.redirectAfterReload && StructKeyExists(url, "reload") && cgi.request_method == "get") {
			if (StructKeyExists(cgi, "path_info") && Len(cgi.path_info)) {
				local.url = cgi.path_info;
			} else if (StructKeyExists(cgi, "path_info")) {
				local.url = "/";
			} else {
				local.url = cgi.script_name;
			}
			local.oldQueryString = ListToArray(cgi.query_string, "&");
			local.newQueryString = [];
			local.iEnd = ArrayLen(local.oldQueryString);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.keyValue = local.oldQueryString[local.i];
				local.key = ListFirst(local.keyValue, "=");
				if (!ListFindNoCase("reload,password,lock", local.key)) {
					ArrayAppend(local.newQueryString, local.keyValue);
				}
			}
			if (ArrayLen(local.newQueryString)) {
				local.queryString = ArrayToList(local.newQueryString, "&");
				local.url = "#local.url#?#local.queryString#";
			}
			$location(url = local.url, addToken = false);
		}
	}
}
