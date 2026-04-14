/**
 * wheels-sentry — Wheels package for Sentry error tracking.
 *
 * Provides automatic SDK initialization, controller mixin methods for
 * capturing errors/messages with Wheels context, and breadcrumb support.
 *
 * Mixin methods available in controllers:
 *   sentryCapture(exception, [level], [additionalData])
 *   sentryMessage(message, [level])
 *   sentrySetUser(userStruct)
 *   sentryAddBreadcrumb(message, [category], [data], [level])
 */
component mixin="controller" output="false" {

	function init() {
		this.version = "3.0";
		initSentry();
		return this;
	}

	/**
	 * Auto-initialize the Sentry SDK if a DSN is available.
	 * Reads from: (1) Wheels setting sentryDSN, (2) SENTRY_DSN env var.
	 * Stores the client in application.sentry.
	 */
	private void function initSentry() {
		if (structKeyExists(application, "sentry"))
			return;

		lock name="sentryForWheelsInit" type="exclusive" timeout="10" {

		if (structKeyExists(application, "sentry"))
			return;

		try {
			var dsn = "";
			try {
				dsn = get("sentryDSN");
			} catch (any e) {}

			if (!len(trim(dsn))) {
				var javaEnv = createObject("java", "java.lang.System").getenv("SENTRY_DSN");
				if (!isNull(javaEnv) && len(trim(javaEnv)))
					dsn = javaEnv;
			}

			if (!len(trim(dsn)))
				return;

			// Determine environment and release
			var appKey = structKeyExists(application, "wheels") ? "wheels" : "$wheels";
			var env = "development";
			if (structKeyExists(application, appKey) && structKeyExists(application[appKey], "environment"))
				env = application[appKey].environment;

			var rel = "unknown";
			try {
				var javaAppVersion = createObject("java", "java.lang.System").getenv("APP_VERSION");
				if (!isNull(javaAppVersion) && len(trim(javaAppVersion)))
					rel = javaAppVersion;
			} catch (any e) {}

			// Read scope settings with defaults
			var scopeSettings = {
				"sendDefaultPii":       $sentryGetSetting("sentrySendDefaultPii", false),
				"includeHeaders":       $sentryGetSetting("sentryIncludeHeaders", true),
				"includeServerContext":  $sentryGetSetting("sentryIncludeServerContext", true),
				"includeUser":          false,
				"includeSession":       false,
				"includeCookies":       false
			};

			// PII settings: individual overrides take precedence, otherwise follow sendDefaultPii
			var pii = scopeSettings.sendDefaultPii;
			scopeSettings.includeUser    = $sentryGetSetting("sentryIncludeUser", pii);
			scopeSettings.includeSession = $sentryGetSetting("sentryIncludeSession", pii);
			scopeSettings.includeCookies = $sentryGetSetting("sentryIncludeCookies", pii);

			application.sentry = new plugins.sentry.SentryClient(
				DSN: dsn,
				environment: env,
				release: rel,
				serverName: cgi.server_name,
				scopeSettings: scopeSettings
			);

			writeLog(
				text="wheels-sentry initialized (env=#env#, release=#rel#, pii=#pii#)",
				type="information",
				file="application"
			);
		} catch (any e) {
			writeLog(
				text="wheels-sentry initialization failed: #e.message#",
				type="error",
				file="application"
			);
		}

		} // end lock
	}

	/**
	 * Read a Wheels setting with a fallback default. Returns the default
	 * if the setting doesn't exist or throws.
	 */
	private any function $sentryGetSetting(required string name, required any defaultValue) {
		try {
			var val = get(arguments.name);
			if (isBoolean(val)) return val;
			if (isSimpleValue(val) && len(val)) return val;
		} catch (any e) {}
		return arguments.defaultValue;
	}

	/**
	 * Capture an exception with Wheels controller/action context.
	 *
	 * @exception      The exception struct to capture.
	 * @level          Sentry level (default: "error").
	 * @additionalData Optional struct of extra data to attach.
	 */
	public void function sentryCapture(
		required any exception,
		string level = "error",
		any additionalData
	) {
		if (!structKeyExists(application, "sentry"))
			return;

		var eventTags = {};
		if (structKeyExists(variables, "params")) {
			var p = variables.params;
			if (structKeyExists(p, "controller"))
				eventTags["wheels.controller"] = p.controller;
			if (structKeyExists(p, "action"))
				eventTags["wheels.action"] = p.action;

			application.sentry.setRequestContext(
				controller: structKeyExists(p, "controller") ? p.controller : "",
				action: structKeyExists(p, "action") ? p.action : "",
				params: p
			);
		}

		var captureArgs = {
			exception: arguments.exception,
			level: arguments.level,
			useThread: true,
			showJavaStackTrace: true,
			userInfo: $sentryGetUser(),
			tags: eventTags
		};

		if (!isNull(arguments.additionalData))
			captureArgs["additionalData"] = arguments.additionalData;

		application.sentry.captureException(argumentCollection: captureArgs);
	}

	/**
	 * Capture a message with Wheels controller/action context.
	 *
	 * @message The message string to send to Sentry.
	 * @level   Sentry level (default: "info").
	 */
	public void function sentryMessage(
		required string message,
		string level = "info"
	) {
		if (!structKeyExists(application, "sentry"))
			return;

		var eventTags = {};
		if (structKeyExists(variables, "params")) {
			var p = variables.params;
			if (structKeyExists(p, "controller"))
				eventTags["wheels.controller"] = p.controller;
			if (structKeyExists(p, "action"))
				eventTags["wheels.action"] = p.action;

			application.sentry.setRequestContext(
				controller: structKeyExists(p, "controller") ? p.controller : "",
				action: structKeyExists(p, "action") ? p.action : "",
				params: p
			);
		}

		application.sentry.captureMessage(
			message: arguments.message,
			level: arguments.level,
			useThread: true,
			userInfo: $sentryGetUser(),
			tags: eventTags
		);
	}

	/**
	 * Set the Sentry user context for the current request.
	 * Call this in a before filter to attach user identity to all events.
	 *
	 * @userStruct Struct with id, email, username, ip_address, etc.
	 */
	public void function sentrySetUser(required struct userStruct) {
		request.sentryUserOverride = arguments.userStruct;
	}

	/**
	 * Add a breadcrumb for the current request.
	 *
	 * @message  Breadcrumb message.
	 * @category Category string (default: "controller").
	 * @data     Optional struct of extra data.
	 * @level    Sentry level (default: "info").
	 */
	public void function sentryAddBreadcrumb(
		required string message,
		string category = "controller",
		struct data = {},
		string level = "info"
	) {
		if (!structKeyExists(application, "sentry"))
			return;

		application.sentry.addBreadcrumb(
			message: arguments.message,
			category: arguments.category,
			data: arguments.data,
			level: arguments.level
		);
	}

	/**
	 * Build user info from request override. Returns empty struct if
	 * no user has been set via sentrySetUser() or if user inclusion is
	 * disabled. Applications should call sentrySetUser() in a before
	 * filter to attach user identity.
	 */
	private struct function $sentryGetUser() {
		if (structKeyExists(request, "sentryUserOverride"))
			return request.sentryUserOverride;
		return {};
	}
}
