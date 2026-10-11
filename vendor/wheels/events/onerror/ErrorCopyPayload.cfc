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
		// Quoted keys throughout: SerializeJSON keeps their case on every engine, so
		// agents reading the JSON see `source`, `exception.type`, … not upper case.
		var payload = {
			"source" = "wheels-error-page",
			"exception" = {
				"type" = $structString(exception, "type"),
				"message" = $structString(exception, "message"),
				"detail" = $structString(exception, "detail")
			},
			"suggestedAction" = $structString(exception, "extendedInfo"),
			"location" = {},
			"sourceSnippet" = {},
			"stack" = [],
			"request" = $requestInfo()
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
				"file" = locationFrame.file,
				"line" = locationFrame.line,
				"type" = locationFrame.type,
				"template" = locationFrame.template
			};
			payload.sourceSnippet = readSnippet(
				templatePath = locationFrame.template,
				lineNumber = locationFrame.line
			);
		}

		if (IsDefined("application.wheels.version") && Len(application.wheels.version)) {
			payload["wheelsVersion"] = application.wheels.version;
		}

		return payload;
	}

	public string function toJson(required any wheelsError) {
		return SerializeJSON(build(wheelsError = arguments.wheelsError));
	}

	/**
	 * The payload as Markdown, for a development error asked for as text/markdown:
	 * a heading with the type and message, the status and request, the suggested
	 * action, the location with its source snippet, then the stack with app, plugin
	 * and library frames listed and framework frames collapsed to a count. Takes a
	 * built payload (or the minimal fallback), so every key is optional.
	 */
	public string function toMarkdown(required struct payload) {
		var nl = Chr(10);
		var p = arguments.payload;
		var exception = StructKeyExists(p, "exception") && IsStruct(p.exception) ? p.exception : {};
		var type = $structString(exception, "type");
		var message = $structString(exception, "message");
		var md = Chr(35) & " " & (Len(type) ? type & ": " : "") & message & nl;
		var detail = $structString(exception, "detail");
		if (Len(detail)) {
			md &= nl & detail & nl;
		}

		var facts = [];
		if (StructKeyExists(p, "statusCode") && IsSimpleValue(p.statusCode) && Len(p.statusCode)) {
			ArrayAppend(facts, "**Status:** " & p.statusCode);
		}
		var requestInfo = StructKeyExists(p, "request") && IsStruct(p.request) ? p.request : {};
		var method = $structString(requestInfo, "method");
		var path = $structString(requestInfo, "path");
		if (Len(method) || Len(path)) {
			ArrayAppend(facts, "**Request:** " & Trim(method & " " & path));
		}
		var version = $structString(p, "wheelsVersion");
		if (Len(version)) {
			ArrayAppend(facts, "**Wheels** " & version);
		}
		if (ArrayLen(facts)) {
			md &= nl & ArrayToList(facts, " | ") & nl;
		}

		var suggested = $structString(p, "suggestedAction");
		if (Len(suggested)) {
			md &= nl & Chr(35) & Chr(35) & " Suggested action" & nl & suggested & nl;
		}

		var location = StructKeyExists(p, "location") && IsStruct(p.location) ? p.location : {};
		var file = $structString(location, "file");
		if (Len(file)) {
			md &= nl & Chr(35) & Chr(35) & " Location" & nl & "`" & file & ":" & $structString(location, "line") & "`" & nl;
			md &= $markdownSnippet(StructKeyExists(p, "sourceSnippet") && IsStruct(p.sourceSnippet) ? p.sourceSnippet : {});
		}

		md &= $markdownStack(StructKeyExists(p, "stack") && IsArray(p.stack) ? p.stack : []);
		return md;
	}

	/**
	 * A fenced snippet: each line numbered, the error line marked with ">".
	 */
	public string function $markdownSnippet(required struct snippet) {
		if (!StructKeyExists(arguments.snippet, "lines") || !IsArray(arguments.snippet.lines) || !ArrayLen(arguments.snippet.lines)) {
			return "";
		}
		var nl = Chr(10);
		var width = Len($structString(arguments.snippet, "endLine"));
		var fence = "````";
		var rv = nl & fence & "cfml" & nl;
		for (var entry in arguments.snippet.lines) {
			var lineNumber = $structString(entry, "line");
			var padded = RepeatString(" ", Max(0, width - Len(lineNumber))) & lineNumber;
			var marker = StructKeyExists(entry, "highlight") && IsBoolean(entry.highlight) && entry.highlight ? ">" : " ";
			rv &= marker & " " & padded & " | " & $structString(entry, "code") & nl;
		}
		return rv & fence & nl;
	}

	/**
	 * The stack as a numbered list of app, plugin and library frames; framework
	 * frames are counted, not listed, to keep the response short.
	 */
	public string function $markdownStack(required array stack) {
		if (!ArrayLen(arguments.stack)) {
			return "";
		}
		var nl = Chr(10);
		var rv = nl & Chr(35) & Chr(35) & " Stack" & nl;
		var shown = 0;
		var hidden = 0;
		for (var frame in arguments.stack) {
			if (!IsStruct(frame)) {
				continue;
			}
			if ($structString(frame, "type") == "framework") {
				hidden++;
				continue;
			}
			shown++;
			rv &= shown & ". " & $structString(frame, "type") & " `" & $structString(frame, "file") & ":" & $structString(frame, "line") & "`" & nl;
		}
		if (hidden) {
			rv &= hidden & " framework frame" & (hidden == 1 ? "" : "s") & " not shown" & nl;
		}
		return rv;
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
					"index" = ArrayLen(frames) + 1,
					"template" = tpl,
					"file" = Replace(tpl, root, ""),
					"line" = frameLine,
					"type" = $frameType(tpl)
				}
			);
		}
		return frames;
	}

	public struct function readSnippet(required string templatePath, required numeric lineNumber, numeric contextLines = 5) {
		var snippet = {
			"startLine" = 0,
			"endLine" = 0,
			"errorLine" = Val(arguments.lineNumber),
			"lines" = []
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
				{"line" = pos, "code" = code, "highlight" = (pos == errorLine)}
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
	 * Same location pick as wheelserror.cfm: the first app frame, wherever it is
	 * (an app that throws directly has it first); with no app frame, the first frame
	 * after the innermost throw site, else the only frame.
	 */
	public struct function $locationFrame(required array frames) {
		var count = ArrayLen(arguments.frames);
		var i = 1;
		for (i = 1; i <= count; i++) {
			if (arguments.frames[i].type == "app") {
				return arguments.frames[i];
			}
		}
		if (count > 1) {
			return arguments.frames[2];
		}
		if (count == 1) {
			return arguments.frames[1];
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
		var info = {"method" = "", "path" = "", "queryString" = ""};
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
			info["requestId"] = request.wheels.requestId;
		}
		return info;
	}

}
