/**
 * wheels-hotwire Plugin
 * Hotwire infrastructure: Turbo Drive, Turbo Frames,
 * Turbo Streams, Stimulus, and Hotwire Native.
 * No CSS opinions — pair with wheels-basecoat or any design system.
 */
component mixin="controller,view" output="false" {

	function init() {
		this.version = "3.0";
		return this;
	}

	// ==============================================
	// INCLUDES
	// ==============================================

	/**
	 * Outputs Turbo and Stimulus script tags for the layout <head>. Does not include any CSS.
	 */
	public string function hotwireIncludes(
		boolean turbo = true,
		boolean stimulus = true,
		string turboVersion = "8",
		string stimulusVersion = "3",
		string turboCacheControl = "no-preview"
	) {
		var local = {};
		savecontent variable="local.html" {
			writeOutput(
				(len(arguments.turboCacheControl) ? '<meta name="turbo-cache-control" content="#arguments.turboCacheControl#">' & chr(10) : '')
				& (arguments.turbo ? '<script type="module">import * as Turbo from "https://cdn.jsdelivr.net/npm/@hotwired/turbo@#arguments.turboVersion#/+esm";</script>' & chr(10) : '')
				& (arguments.stimulus ? '<script type="module">import { Application } from "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@#arguments.stimulusVersion#/+esm"; window.Stimulus = Application.start();</script>' & chr(10) : '')
			);
		}
		return trim(local.html);
	}

	// ==============================================
	// REQUEST DETECTION
	// ==============================================

	/**
	 * Returns true if the current request accepts Turbo Stream responses (checks Accept header).
	 */
	public boolean function isHotwireRequest() {
		try {
			var accept = getHTTPRequestData().headers["Accept"];
			return findNoCase("text/vnd.turbo-stream.html", accept) > 0;
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Returns true if the current request was initiated by a Turbo Frame (checks Turbo-Frame header).
	 */
	public boolean function isTurboFrameRequest() {
		try {
			return structKeyExists(getHTTPRequestData().headers, "Turbo-Frame");
		} catch (any e) {
			return false;
		}
	}

	/**
	 * Returns the requesting Turbo Frame ID, or empty string if not a frame request.
	 */
	public string function turboFrameRequestId() {
		try {
			var headers = getHTTPRequestData().headers;
			if (structKeyExists(headers, "Turbo-Frame"))
				return headers["Turbo-Frame"];
		} catch (any e) {}
		return "";
	}

	/**
	 * Returns true if the request comes from a Hotwire Native iOS/Android app (checks User-Agent for 'Turbo Native').
	 */
	public boolean function hotwireNativeApp() {
		try {
			return findNoCase("Turbo Native", getHTTPRequestData().headers["User-Agent"]) > 0;
		} catch (any e) {
			return false;
		}
	}

	// ==============================================
	// TURBO FRAMES
	// ==============================================

	/**
	 * Opens a <turbo-frame> tag. Close with turboFrameEnd().
	 */
	public string function turboFrame(
		required string id,
		string src = "",
		string loading = "",
		string target = "",
		boolean autoscroll = false,
		string class = "",
		boolean disabled = false
	) {
		var attrs = 'id="#arguments.id#"';

		if (len(arguments.src)) attrs &= ' src="#arguments.src#"';
		if (len(arguments.loading)) attrs &= ' loading="#arguments.loading#"';
		if (len(arguments.target)) attrs &= ' target="#arguments.target#"';
		if (arguments.autoscroll) attrs &= ' autoscroll';
		if (arguments.disabled) attrs &= ' disabled';
		if (len(arguments.class)) attrs &= ' class="#arguments.class#"';

		return '<turbo-frame #attrs#>';
	}

	/**
	 * Closes a </turbo-frame> tag.
	 */
	public string function turboFrameEnd() {
		return '</turbo-frame>';
	}

	// ==============================================
	// TURBO STREAMS
	// ==============================================

	/** Turbo Stream: append content as the last child of the target element. */
	public string function turboStreamAppend(required string target, required string content) {
		return $turboStreamAction("append", arguments.target, arguments.content);
	}

	/** Turbo Stream: prepend content as the first child of the target element. */
	public string function turboStreamPrepend(required string target, required string content) {
		return $turboStreamAction("prepend", arguments.target, arguments.content);
	}

	/** Turbo Stream: replace the entire target element with new content. */
	public string function turboStreamReplace(required string target, required string content) {
		return $turboStreamAction("replace", arguments.target, arguments.content);
	}

	/** Turbo Stream: update the inner HTML of the target element (keeps the element itself). */
	public string function turboStreamUpdate(required string target, required string content) {
		return $turboStreamAction("update", arguments.target, arguments.content);
	}

	/** Turbo Stream: remove the target element from the DOM. */
	public string function turboStreamRemove(required string target) {
		return '<turbo-stream action="remove" target="#arguments.target#"></turbo-stream>';
	}

	/** Turbo Stream: insert content before the target element. */
	public string function turboStreamBefore(required string target, required string content) {
		return $turboStreamAction("before", arguments.target, arguments.content);
	}

	/** Turbo Stream: insert content after the target element. */
	public string function turboStreamAfter(required string target, required string content) {
		return $turboStreamAction("after", arguments.target, arguments.content);
	}

	/** Turbo Stream: trigger a full page refresh via morph. */
	public string function turboStreamRefresh() {
		return '<turbo-stream action="refresh"></turbo-stream>';
	}

	/**
	 * Controller helper: sends a Turbo Stream response. Pass a single stream string or an array of stream strings.
	 */
	public void function renderTurboStream(required any streams) {
		var streamArray = isSimpleValue(arguments.streams) ? [arguments.streams] : arguments.streams;
		var body = arrayToList(streamArray, chr(10));

		cfcontent(type="text/vnd.turbo-stream.html", reset="true");
		writeOutput(body);
		abort;
	}

	/** Private: builds a turbo-stream element with template wrapper */
	private string function $turboStreamAction(
		required string action,
		required string target,
		required string content
	) {
		return '<turbo-stream action="#arguments.action#" target="#arguments.target#"><template>#arguments.content#</template></turbo-stream>';
	}

	// ==============================================
	// HOTWIRE NATIVE NAVIGATION
	// ==============================================

	/**
	 * Hotwire Native: pops/dismisses current screen. Web: normal redirect.
	 * Pass standard Wheels redirectTo() arguments.
	 */
	public void function recedeOrRedirectTo(
		string route = "",
		string controller = "",
		string action = "",
		string key = ""
	) {
		if (hotwireNativeApp()) {
			cfheader(statuscode="303");
			cfheader(name="Location", value="/hotwire/native/recede");
			abort;
		} else {
			redirectTo(argumentCollection=arguments);
		}
	}

	/** Hotwire Native: refreshes current screen. Web: normal redirect. */
	public void function refreshOrRedirectTo(
		string route = "",
		string controller = "",
		string action = "",
		string key = ""
	) {
		if (hotwireNativeApp()) {
			cfheader(statuscode="303");
			cfheader(name="Location", value="/hotwire/native/refresh");
			abort;
		} else {
			redirectTo(argumentCollection=arguments);
		}
	}

	/** Hotwire Native: resumes with no action. Web: normal redirect. */
	public void function resumeOrRedirectTo(
		string route = "",
		string controller = "",
		string action = "",
		string key = ""
	) {
		if (hotwireNativeApp()) {
			cfheader(statuscode="303");
			cfheader(name="Location", value="/hotwire/native/resume");
			abort;
		} else {
			redirectTo(argumentCollection=arguments);
		}
	}

	/**
	 * Renders JSON path configuration for Hotwire Native apps.
	 */
	public void function hotwireNativePathConfiguration(
		struct settings = {},
		array rules = []
	) {
		var config = {};

		if (!structIsEmpty(arguments.settings))
			config["settings"] = arguments.settings;

		if (arrayLen(arguments.rules) > 0) {
			config["rules"] = arguments.rules;
		} else {
			config["rules"] = [
				{
					"patterns": [".*"],
					"properties": {"context": "default", "pull_to_refresh_enabled": true}
				},
				{
					"patterns": ["/new$", "/edit$"],
					"properties": {"context": "modal", "pull_to_refresh_enabled": false}
				}
			];
		}

		cfcontent(type="application/json", reset="true");
		writeOutput(serializeJSON(config));
		abort;
	}

	// ==============================================
	// STIMULUS CONVENIENCE HELPERS
	// ==============================================

	/** Generates a data-controller attribute value. Pass one or more controller names. */
	public string function stimulusController(required string controllers) {
		return 'data-controller="#trim(arguments.controllers)#"';
	}

	/** Generates a data-action attribute value. Pass one or more action descriptors. */
	public string function stimulusAction(required string actions) {
		return 'data-action="#trim(arguments.actions)#"';
	}

	/** Generates a data-{controller}-target attribute. */
	public string function stimulusTarget(required string controller, required string name) {
		return 'data-#arguments.controller#-target="#arguments.name#"';
	}

	/** Generates a data-{controller}-{name}-value attribute. */
	public string function stimulusValue(required string controller, required string name, required string value) {
		return 'data-#arguments.controller#-#arguments.name#-value="#arguments.value#"';
	}

}
