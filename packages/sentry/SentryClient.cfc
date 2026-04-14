/**
 * Sentry SDK for ColdFusion / Wheels
 *
 * Based on sentry-cfml by GiancarloGomez (https://github.com/GiancarloGomez/sentry-cfml)
 * Enhanced with Wheels-aware context enrichment, breadcrumbs, and modern envelope API.
 *
 * Sentry SDK Documentation: https://develop.sentry.dev/sdk/
 */
component displayname="SentryClient" output="false" accessors="true" {

	property name="DSN" type="string";
	property name="environment" type="string";
	property name="levels" type="array";
	property name="logger" type="string" default="sentry.cfml.wheels";
	property name="platform" type="string" default="java";
	property name="release" type="string";
	property name="projectID";
	property name="publicKey";
	property name="version" type="string" default="1.0.0";
	property name="sentryUrl" type="string" default="https://sentry.io";
	property name="sentryVersion" type="string" default="7";
	property name="serverName" type="string";
	property name="defaultTags" type="struct";
	property name="scopeSettings" type="struct";

	/**
	 * @release        The release version of the application.
	 * @environment    The environment name, such as 'production' or 'staging'.
	 * @DSN            A Sentry DSN string (modern or legacy format).
	 * @publicKey      The Public Key for your Sentry Account.
	 * @projectID      The Sentry Project ID.
	 * @sentryUrl      The Sentry API url (defaults to https://sentry.io).
	 * @serverName     The name of the server (defaults to cgi.server_name).
	 * @scopeSettings  Struct controlling which data scopes are included in events.
	 */
	function init(
		required string release,
		required string environment,
		string DSN,
		string publicKey,
		string privateKey,
		numeric projectID,
		string sentryUrl,
		string serverName = cgi.server_name,
		struct scopeSettings = {}
	) {
		if (structKeyExists(arguments, "DSN") && len(trim(arguments.DSN))) {
			setDSN(arguments.DSN);
			parseDSN(arguments.DSN);
		} else if (
			structKeyExists(arguments, "publicKey") && len(trim(arguments.publicKey)) &&
			structKeyExists(arguments, "projectID") && len(trim(arguments.projectID))
		) {
			setPublicKey(arguments.publicKey);
			setProjectID(arguments.projectID);
			setDSN("https://" & arguments.publicKey & "@sentry.io/" & arguments.projectID);
		} else {
			throw(message="You must pass a valid DSN or Project Keys and ID to instantiate the Sentry CFML Client.");
		}

		setLevels(["fatal", "error", "warning", "info", "debug"]);
		setEnvironment(arguments.environment);
		setRelease(arguments.release);
		setServerName(arguments.serverName);

		if (structKeyExists(arguments, "sentryUrl") && len(trim(arguments.sentryUrl)))
			setSentryUrl(arguments.sentryUrl);

		// Scope settings with defaults
		var defaults = {
			"includeHeaders": true,
			"includeServerContext": true,
			"includeUser": false,
			"includeSession": false,
			"includeCookies": false,
			"sendDefaultPii": false
		};
		structAppend(defaults, arguments.scopeSettings, true);
		setScopeSettings(defaults);

		setDefaultTags(buildDefaultTags());

		return this;
	}

	/**
	 * Build default tags that are attached to every Sentry event.
	 */
	private struct function buildDefaultTags() {
		var tags = {};

		if (structKeyExists(server, "lucee")) {
			tags["cfml.engine"] = "lucee";
			tags["cfml.engine.version"] = server.lucee.version;
		} else if (structKeyExists(server, "coldfusion") && structKeyExists(server.coldfusion, "productName")) {
			tags["cfml.engine"] = "coldfusion";
			tags["cfml.engine.version"] = server.coldfusion.productVersion;
		} else {
			tags["cfml.engine"] = "unknown";
		}

		tags["cfml.framework"] = "wheels";
		var appKey = structKeyExists(application, "wheels") ? "wheels" : "$wheels";
		if (structKeyExists(application, appKey) && structKeyExists(application[appKey], "version"))
			tags["cfml.framework.version"] = application[appKey].version;
		if (structKeyExists(application, appKey) && structKeyExists(application[appKey], "environment"))
			tags["wheels.environment"] = application[appKey].environment;

		return tags;
	}

	/**
	 * Parses a Sentry DSN. Supports both modern and legacy formats:
	 *   Modern:  https://{PUBLIC_KEY}@{HOST}/{PROJECT_ID}
	 *   Legacy:  https://{PUBLIC_KEY}:{SECRET_KEY}@{HOST}/{PROJECT_ID}
	 */
	private void function parseDSN(required string DSN) {
		var modernPattern = "^(?:(\w+):)?\/\/(\w+)@([\w\.\-]+)\/(.+)$";
		var modernResult = reFind(modernPattern, arguments.DSN, 1, true);

		// pos[1] is the full match; capture groups start at pos[2]
		if (modernResult.pos[1] > 0 && arrayLen(modernResult.pos) == 5) {
			setSentryUrl(mid(arguments.DSN, modernResult.pos[2], modernResult.len[2]) & "://" & mid(arguments.DSN, modernResult.pos[4], modernResult.len[4]));
			setPublicKey(mid(arguments.DSN, modernResult.pos[3], modernResult.len[3]));
			setProjectID(mid(arguments.DSN, modernResult.pos[5], modernResult.len[5]));
			return;
		}

		var legacyPattern = "^(?:(\w+):)?\/\/(\w+):(\w+)?@([\w\.\-]+)\/(.+)$";
		var legacyResult = reFind(legacyPattern, arguments.DSN, 1, true);

		// pos[1] is full match; groups at pos[2..6]
		if (legacyResult.pos[1] > 0 && arrayLen(legacyResult.pos) == 6) {
			setSentryUrl(mid(arguments.DSN, legacyResult.pos[2], legacyResult.len[2]) & "://" & mid(arguments.DSN, legacyResult.pos[5], legacyResult.len[5]));
			setPublicKey(mid(arguments.DSN, legacyResult.pos[3], legacyResult.len[3]));
			setProjectID(mid(arguments.DSN, legacyResult.pos[6], legacyResult.len[6]));
			return;
		}

		throw(message="Error parsing Sentry DSN: #arguments.DSN#");
	}

	private void function validateLevel(required string level) {
		if (!getLevels().find(arguments.level))
			throw(message="Error Type must be one of the following: " & getLevels().toString());
	}

	/**
	 * Set request context for Wheels controller/action enrichment.
	 */
	public void function setRequestContext(
		required string controller,
		required string action,
		struct params = {}
	) {
		request.sentryContext = {
			"controller": arguments.controller,
			"action": arguments.action,
			"params": arguments.params
		};
	}

	/**
	 * Add a breadcrumb for the current request.
	 */
	public void function addBreadcrumb(
		required string message,
		string category = "app",
		struct data = {},
		string level = "info"
	) {
		if (!structKeyExists(request, "sentryBreadcrumbs"))
			request.sentryBreadcrumbs = [];

		var crumb = {
			"message": arguments.message,
			"category": arguments.category,
			"level": arguments.level,
			"timestamp": int(now().getTime() / 1000)
		};

		if (!structIsEmpty(arguments.data))
			crumb["data"] = arguments.data;

		arrayAppend(request.sentryBreadcrumbs, crumb);
	}

	/**
	 * Capture a message.
	 */
	public any function captureMessage(
		required string message,
		string level = "info",
		string path = "",
		array params,
		any cgiVars = cgi,
		boolean useThread = false,
		struct userInfo = {},
		struct tags = {}
	) {
		validateLevel(arguments.level);

		if (len(trim(arguments.message)) > 1000)
			arguments.message = left(arguments.message, 997) & "...";

		var sentryEvent = {
			"level": arguments.level,
			"message": {
				"formatted": arguments.message
			}
		};

		if (structKeyExists(arguments, "params"))
			sentryEvent["message"]["params"] = arguments.params;

		capture(
			captureStruct: sentryEvent,
			path: arguments.path,
			cgiVars: arguments.cgiVars,
			useThread: arguments.useThread,
			userInfo: arguments.userInfo,
			tags: arguments.tags
		);
	}

	/**
	 * Capture an exception with full stack trace.
	 */
	public any function captureException(
		required any exception,
		string level = "error",
		string path = "",
		boolean oneLineStackTrace = false,
		boolean showJavaStackTrace = false,
		boolean removeTabsOnJavaStackTrace = false,
		any additionalData,
		any cgiVars = cgi,
		boolean useThread = false,
		struct userInfo = {},
		struct tags = {}
	) {
		var file                 = "";
		var fileArray            = "";
		var currentTemplate      = "";
		var tagContext            = structKeyExists(arguments.exception, "TagContext") ? arguments.exception.TagContext : [];
		var frames               = [];
		var exMessage            = structKeyExists(arguments.exception, "message") ? arguments.exception.message : "";
		var exDetail             = structKeyExists(arguments.exception, "detail") ? arguments.exception.detail : "";
		var exType               = structKeyExists(arguments.exception, "type") ? arguments.exception.type : "Application";

		validateLevel(arguments.level);

		if (arguments.oneLineStackTrace && arrayLen(tagContext) > 0)
			tagContext = [tagContext[1]];

		for (var i = arrayLen(tagContext); i >= 1; i--) {
			if (compareNoCase(tagContext[i]["TEMPLATE"], currentTemplate)) {
				fileArray = [];
				if (fileExists(tagContext[i]["TEMPLATE"])) {
					try {
						fileArray = ListToArray(FileRead(tagContext[i]["TEMPLATE"]), Chr(10));
					} catch (any e) {
						fileArray = [];
					}
				}
				currentTemplate = tagContext[i]["TEMPLATE"];
			}

			var frame = {
				"abs_path": tagContext[i]["TEMPLATE"],
				"filename": tagContext[i]["TEMPLATE"],
				"lineno": tagContext[i]["LINE"],
				"function": (i == 1 && structKeyExists(tagContext[i], "COLUMN"))
					? "column #tagContext[i]['COLUMN']#"
					: tagContext[i]["ID"]
			};

			frame["pre_context"] = [];
			if (isArray(fileArray) && tagContext[i]["LINE"] - 3 >= 1)
				arrayAppend(frame["pre_context"], fileArray[tagContext[i]["LINE"] - 3]);
			if (isArray(fileArray) && tagContext[i]["LINE"] - 2 >= 1)
				arrayAppend(frame["pre_context"], fileArray[tagContext[i]["LINE"] - 2]);
			if (isArray(fileArray) && tagContext[i]["LINE"] - 1 >= 1)
				arrayAppend(frame["pre_context"], fileArray[tagContext[i]["LINE"] - 1]);
			if (isArray(fileArray) && arrayLen(fileArray) >= tagContext[i]["LINE"])
				frame["context_line"] = fileArray[tagContext[i]["LINE"]];

			frame["post_context"] = [];
			if (isArray(fileArray) && arrayLen(fileArray) >= tagContext[i]["LINE"] + 1)
				arrayAppend(frame["post_context"], fileArray[tagContext[i]["LINE"] + 1]);
			if (isArray(fileArray) && arrayLen(fileArray) >= tagContext[i]["LINE"] + 2)
				arrayAppend(frame["post_context"], fileArray[tagContext[i]["LINE"] + 2]);

			arrayAppend(frames, frame);
		}

		var sentryEvent = {
			"level": arguments.level,
			"exception": {
				"values": [{
					"type": exType,
					"value": trim(exMessage & " " & exDetail),
					"stacktrace": {
						"frames": frames
					}
				}]
			}
		};

		var extra = {};
		if (arguments.showJavaStackTrace && structKeyExists(arguments.exception, "StackTrace")) {
			var st = reReplace(arguments.exception.StackTrace, "\r", "", "All");
			if (arguments.removeTabsOnJavaStackTrace)
				st = reReplace(st, "\t", "", "All");
			extra["Java StackTrace"] = listToArray(st, chr(10));
		}

		if (!isNull(arguments.additionalData))
			extra["Additional Data"] = arguments.additionalData;

		if (structCount(extra))
			sentryEvent["extra"] = extra;

		capture(
			captureStruct: sentryEvent,
			path: arguments.path,
			cgiVars: arguments.cgiVars,
			useThread: arguments.useThread,
			userInfo: arguments.userInfo,
			tags: arguments.tags
		);
	}

	/**
	 * Build envelope and post event to Sentry.
	 * Enriches the event with tags, contexts, and request data based on scopeSettings.
	 */
	public void function capture(
		required any captureStruct,
		any cgiVars = cgi,
		string path = "",
		boolean useThread = false,
		struct userInfo = {},
		struct tags = {}
	) {
		var timeVars = getTimeVars();
		var eventId  = lcase(replace(createUUID(), "-", "", "all"));
		var ss       = getScopeSettings();

		arguments.captureStruct["event_id"]    = eventId;
		arguments.captureStruct["timestamp"]   = timeVars.timeStamp;
		arguments.captureStruct["logger"]      = getLogger();
		arguments.captureStruct["project"]     = getProjectID();
		arguments.captureStruct["server_name"] = getServerName();
		arguments.captureStruct["platform"]    = getPlatform();
		arguments.captureStruct["release"]     = getRelease();
		arguments.captureStruct["environment"] = getEnvironment();

		arguments.captureStruct["sdk"] = {
			"name": getLogger(),
			"version": getVersion()
		};

		// Tags: defaults < per-event < request context
		var mergedTags = structCopy(getDefaultTags());
		structAppend(mergedTags, arguments.tags, true);

		if (structKeyExists(request, "sentryContext")) {
			var ctx = request.sentryContext;
			if (structKeyExists(ctx, "controller") && len(ctx.controller))
				mergedTags["wheels.controller"] = ctx.controller;
			if (structKeyExists(ctx, "action") && len(ctx.action))
				mergedTags["wheels.action"] = ctx.action;

			if (!structKeyExists(arguments.captureStruct, "contexts"))
				arguments.captureStruct["contexts"] = {};
			arguments.captureStruct["contexts"]["wheels"] = {
				"controller": ctx.controller,
				"action": ctx.action
			};
			if (structKeyExists(ctx, "params") && structKeyExists(ctx.params, "route"))
				arguments.captureStruct["contexts"]["wheels"]["route"] = ctx.params.route;
		}

		arguments.captureStruct["tags"] = mergedTags;

		// User context (only if includeUser is true and user data was provided)
		if (ss.includeUser && !structIsEmpty(arguments.userInfo))
			arguments.captureStruct["user"] = arguments.userInfo;

		// Breadcrumbs (always included — no PII)
		if (structKeyExists(request, "sentryBreadcrumbs") && arrayLen(request.sentryBreadcrumbs)) {
			arguments.captureStruct["breadcrumbs"] = {
				"values": request.sentryBreadcrumbs
			};
		}

		// Request context — always include URL and method
		arguments.path = trim(arguments.path);
		if (!len(arguments.path))
			arguments.path = "http" & (arguments.cgiVars.server_port_secure ? "s" : "") & "://" & arguments.cgiVars.server_name & arguments.cgiVars.script_name;

		var requestData = {
			"url":          arguments.path,
			"method":       arguments.cgiVars.request_method,
			"query_string": arguments.cgiVars.query_string
		};

		if (ss.includeHeaders) {
			try {
				requestData["headers"] = getHTTPRequestData(false).headers;
			} catch (any e) {}
		}

		if (ss.includeCookies) {
			try {
				requestData["cookies"] = cookie;
			} catch (any e) {}
		}

		arguments.captureStruct["request"] = requestData;

		// Contexts
		if (!structKeyExists(arguments.captureStruct, "contexts"))
			arguments.captureStruct["contexts"] = {};

		// Server context (non-PII)
		if (ss.includeServerContext) {
			arguments.captureStruct["contexts"]["server"] = {
				"server_name": arguments.cgiVars.server_name,
				"server_port": arguments.cgiVars.server_port,
				"remote_addr": arguments.cgiVars.remote_addr,
				"http_host":   arguments.cgiVars.http_host
			};
		}

		// Session context (PII — opt-in)
		if (ss.includeSession) {
			try {
				if (isDefined("session")) {
					var sessionData = {};
					for (var key in session) {
						if (!listFindNoCase("sessionid,urltoken,cfid,cftoken", key)) {
							var val = session[key];
							if (isSimpleValue(val))
								sessionData[key] = val;
							else if (isStruct(val))
								sessionData[key] = "[struct]";
							else if (isArray(val))
								sessionData[key] = "[array:#arrayLen(val)#]";
						}
					}
					if (!structIsEmpty(sessionData))
						arguments.captureStruct["contexts"]["session"] = sessionData;
				}
			} catch (any e) {}
		}

		// App context (non-PII — always included)
		arguments.captureStruct["contexts"]["app"] = {
			"environment": getEnvironment(),
			"release": getRelease()
		};
		if (structKeyExists(application, "wheels") && structKeyExists(application.wheels, "environment"))
			arguments.captureStruct["contexts"]["app"]["wheels_environment"] = application.wheels.environment;

		// Build Sentry envelope
		var eventJson = serializeJSON(arguments.captureStruct);
		var envelopeHeader = '{"event_id":"' & eventId & '"}';
		var itemHeader = '{"type":"event"}';
		var envelope = envelopeHeader & chr(10) & itemHeader & chr(10) & eventJson;

		if (arguments.useThread) {
			cfthread(
				action="run",
				name="sentry-thread-#createUUID()#",
				envelope=envelope
			) {
				post(envelope);
			}
		} else {
			post(envelope);
		}
	}

	/**
	 * Post envelope to Sentry via REST API.
	 */
	private void function post(required string body) {
		var http = {};
		var apiUrl = getSentryUrl() & "/api/" & getProjectID() & "/envelope/";
		cfhttp(
			url: apiUrl,
			method: "post",
			timeout: "5",
			result: "http"
		) {
			cfhttpparam(type="header", name="Content-Type", value="application/x-sentry-envelope");
			cfhttpparam(type="header", name="X-Sentry-Auth", value="Sentry sentry_version=#getSentryVersion()#, sentry_key=#getPublicKey()#, sentry_client=#getLogger()#/#getVersion()#");
			cfhttpparam(type="body", value=arguments.body);
		}
		if (Left(http.statuscode, 3) != "200")
			writeLog(text="Sentry POST failed (#http.statuscode#): #apiUrl#", type="warning", file="application");
	}

	private struct function getTimeVars() {
		var time = now();
		var timeVars = {
			"time": int(time.getTime() / 1000),
			"utcNowTime": dateConvert("Local2UTC", time)
		};
		timeVars.timeStamp = dateformat(timeVars.utcNowTime, "yyyy-mm-dd") & "T" & timeFormat(timeVars.utcNowTime, "HH:mm:ss") & "Z";
		return timeVars;
	}
}
