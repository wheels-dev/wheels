<cfscript>
/**
 * One-line session-auth wiring for `config/services.cfm`.
 *
 * The auth subsystem ships complete (Authenticator strategy registry +
 * SessionStrategy with login/logout/currentUser and SID rotation) but
 * wiring it by hand spans two files: map the singletons here, then
 * register the strategy in `app/events/onapplicationstart.cfm`.
 * `enableSession()` collapses that into one idempotent call:
 *
 *     // config/services.cfm
 *     enableSession(sessionKey = "wheels.auth");
 *
 * The DI container is available in services.cfm (it is NOT available in
 * config/app.cfm — services.cfm is loaded after the container is built).
 * Manual wiring keeps working; this helper is the convenience path.
 */
public any function enableSession(string sessionKey = "wheels.auth", any onLogin = "", any onLogout = "") {
	// Guard: enableSession() belongs in config/services.cfm, where the
	// container exists. Fail with a pointer rather than an opaque scope
	// error when it is called from a context without one.
	try {
		var di = injector();
	} catch (any e) {
		Throw(
			type = "Wheels.Injector",
			message = "enableSession() requires the DI container — call it from config/services.cfm (loaded at application start).",
			detail = e.message
		);
	}
	if (!isObject(di)) {
		Throw(
			type = "Wheels.Injector",
			message = "enableSession() requires the DI container — call it from config/services.cfm (loaded at application start)."
		);
	}

	// Map the singletons only when they aren't already mapped, so manual
	// wiring and repeat calls stay idempotent.
	if (!di.containsInstance("authenticator")) {
		di.map("authenticator").to("wheels.auth.Authenticator").asSingleton();
	}
	if (!di.containsInstance("sessionStrategy")) {
		di.map("sessionStrategy").to("wheels.auth.SessionStrategy").asSingleton();
	}

	// Resolve with explicit initArguments: the singleton cache honors the
	// first resolution's arguments, so a custom sessionKey/callbacks stick
	// even if something else resolved the strategy first with defaults.
	var authenticator = service("authenticator");
	var strategy = di.getInstance(
		"sessionStrategy",
		{ sessionKey: arguments.sessionKey, onLogin: arguments.onLogin, onLogout: arguments.onLogout }
	);

	// Register once. Repeat calls (dev reloads, double-includes) must not
	// stack duplicate registrations.
	if (!authenticator.hasStrategy("session")) {
		authenticator.registerStrategy(name = "session", strategy = strategy);
	}

	return strategy;
}
</cfscript>
