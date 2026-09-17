/**
 * Builds a clipboard-ready JSON dump of a Wheels error-page exception.
 *
 * Used by `wheelserror.cfm` so a single Copy click can paste type, message,
 * suggested action, location, source snippet, and classified stack frames
 * into a coding agent. Standalone (not mixed in) so the template can
 * `CreateObject` it from `application.wo` includes as well as EventMethods.
 */
component output="false" {

	/**
	 * Structured payload for the development error page clipboard.
	 * The exception argument is untyped: Adobe's validator rejects a cfcatch
	 * object passed to a struct-typed parameter (same reason cfmlerror.cfm
	 * leaves its exception argument untyped).
	 */
	public struct function build(required any wheelsError) {
		var exception = arguments.wheelsError;
		var payload = {
			source = "wheels-error-page",
			exception = {
				type = $structString(exception, "type"),
				message = $structString(exception, "message"),
				detail = $structString(exception, "detail")
			},
			suggestedAction = $structString(exception, "extendedInfo"),
			location = {},
			sourceSnippet = {},
			stack = [],
			request = $requestInfo()
		};

		var tagContext = [];
		if (StructKeyExists(exception, "tagContext") && IsArray(exception.tagContext)) {
			tagContext = exception.tagContext;
		}
		var frames = classifyFrames(tagContext = tagContext);
		payload.stack = frames;

		var locationFrame = $locationFrame(frames);
		if (!StructIsEmpty(locationFrame)) {
			payload.location = {
				file = locationFrame.file,
				line = locationFrame.line,
				type = locationFrame.type,
				template = locationFrame.template
			};
			payload.sourceSnippet = readSnippet(
				templatePath = locationFrame.template,
				lineNumber = locationFrame.line
			);
		}

		if (IsDefined("application.wheels.version") && Len(application.wheels.version)) {
			payload.wheelsVersion = application.wheels.version;
		}

		return payload;
	}

	public string function toJson(required any wheelsError) {
		return SerializeJSON(build(wheelsError = arguments.wheelsError));
	}

	/**
	 * Classify every tagContext entry the same way the error page does:
	 * framework (`vendor/wheels`, public/index.cfm, public/Application.cfc),
	 * library (other `vendor/`), plugin (`plugins/`), otherwise app.
	 */
	public array function classifyFrames(required any tagContext, string appRoot = "") {
		var frames = [];
		if (!IsArray(arguments.tagContext)) {
			return frames;
		}
		var root = Len(arguments.appRoot) ? arguments.appRoot : $appRoot();
		var count = ArrayLen(arguments.tagContext);
		var i = 1;
		for (i = 1; i <= count; i++) {
			var entry = arguments.tagContext[i];
			if (!IsStruct(entry) || !StructKeyExists(entry, "template")) {
				continue;
			}
			var tpl = entry.template;
			if (!IsSimpleValue(tpl) || !Len(tpl)) {
				continue;
			}
			var frameLine = 0;
			if (StructKeyExists(entry, "line") && IsNumeric(entry.line)) {
				frameLine = Val(entry.line);
			}
			ArrayAppend(
				frames,
				{
					index = ArrayLen(frames) + 1,
					template = tpl,
					file = Replace(tpl, root, ""),
					line = frameLine,
					type = $frameType(tpl)
				}
			);
		}
		return frames;
	}

	public struct function readSnippet(required string templatePath, required numeric lineNumber, numeric contextLines = 5) {
		var snippet = {
			startLine = 0,
			endLine = 0,
			errorLine = Val(arguments.lineNumber),
			lines = []
		};
		if (!Len(arguments.templatePath) || !FileExists(arguments.templatePath)) {
			return snippet;
		}
		var state = {ok = false, content = ""};
		try {
			state.content = FileRead(arguments.templatePath);
			state.ok = true;
		} catch (any e) {
			state.ok = false;
		}
		if (!state.ok || !Len(state.content)) {
			return snippet;
		}
		var normalized = Replace(state.content, Chr(13) & Chr(10), Chr(10), "all");
		normalized = Replace(normalized, Chr(13), Chr(10), "all");
		var allLines = ListToArray(normalized, Chr(10), true);
		var total = ArrayLen(allLines);
		if (!total) {
			return snippet;
		}
		var errorLine = Val(arguments.lineNumber);
		if (errorLine < 1) {
			errorLine = 1;
		}
		if (errorLine > total) {
			errorLine = total;
		}
		var radius = Val(arguments.contextLines);
		if (radius < 0) {
			radius = 0;
		}
		var startLine = Max(1, errorLine - radius);
		var endLine = Min(total, errorLine + radius);
		snippet.startLine = startLine;
		snippet.endLine = endLine;
		snippet.errorLine = errorLine;
		var pos = startLine;
		for (pos = startLine; pos <= endLine; pos++) {
			var code = allLines[pos];
			if (!IsSimpleValue(code)) {
				code = "";
			}
			if (Len(code) > 500) {
				code = Left(code, 500) & "...";
			}
			ArrayAppend(
				snippet.lines,
				{line = pos, code = code, highlight = (pos == errorLine)}
			);
		}
		return snippet;
	}

	public string function $appRoot() {
		var path = GetDirectoryFromPath(GetBaseTemplatePath());
		if (FindNoCase("/public/", path) || FindNoCase("\public\", path)) {
			return REReplaceNoCase(path, "[/\\]public[/\\]?$", "/");
		}
		return path;
	}

	public string function $frameType(required string templatePath) {
		var tpl = arguments.templatePath;
		if (FindNoCase("vendor/wheels/", tpl) || FindNoCase("vendor\wheels\", tpl)) {
			return "framework";
		}
		if (FindNoCase("/vendor/", tpl) || FindNoCase("\vendor\", tpl)) {
			return "library";
		}
		if (FindNoCase("/plugins/", tpl) || FindNoCase("\plugins\", tpl)) {
			return "plugin";
		}
		var fileName = GetFileFromPath(tpl);
		if (fileName == "index.cfm" && FindNoCase("public", tpl)) {
			return "framework";
		}
		if (fileName == "Application.cfc" && FindNoCase("public", tpl)) {
			return "framework";
		}
		return "app";
	}

	/**
	 * Same location pick as wheelserror.cfm: ignore the first tagContext
	 * entry (typically the framework throw site), prefer the first app
	 * frame, otherwise the first remaining frame.
	 */
	public struct function $locationFrame(required array frames) {
		var candidates = [];
		var count = ArrayLen(arguments.frames);
		var i = 1;
		if (count > 1) {
			for (i = 2; i <= count; i++) {
				ArrayAppend(candidates, arguments.frames[i]);
			}
		} else if (count == 1) {
			ArrayAppend(candidates, arguments.frames[1]);
		}
		var candidateCount = ArrayLen(candidates);
		for (i = 1; i <= candidateCount; i++) {
			if (candidates[i].type == "app") {
				return candidates[i];
			}
		}
		if (candidateCount) {
			return candidates[1];
		}
		return {};
	}

	private string function $structString(required any data, required string key) {
		if (!IsStruct(arguments.data) || !StructKeyExists(arguments.data, arguments.key)) {
			return "";
		}
		var value = arguments.data[arguments.key];
		if (!IsSimpleValue(value)) {
			return "";
		}
		return value;
	}

	private struct function $requestInfo() {
		var info = {method = "", path = "", queryString = ""};
		if (IsDefined("cgi.request_method")) {
			info.method = cgi.request_method;
		}
		if (IsDefined("request.cgi.path_info") && Len(request.cgi.path_info)) {
			info.path = request.cgi.path_info;
		} else if (IsDefined("cgi.path_info") && Len(cgi.path_info)) {
			info.path = cgi.path_info;
		} else if (IsDefined("cgi.script_name")) {
			info.path = cgi.script_name;
		}
		if (IsDefined("cgi.query_string")) {
			info.queryString = cgi.query_string;
		}
		if (IsDefined("request.wheels.requestId") && Len(request.wheels.requestId)) {
			info.requestId = request.wheels.requestId;
		}
		return info;
	}

}
