component extends="wheels.WheelsTest" {

	function run() {

		describe("ErrorCopyPayload builder", () => {

			it("includes exception type, message, and suggested action", () => {
				var builder = CreateObject("component", "wheels.events.onerror.ErrorCopyPayload");
				var payload = builder.build({
					type = "Wheels.ViewNotFound",
					message = "Could not find the view `show`",
					extendedInfo = "Create app/views/users/show.cfm",
					tagContext = []
				});
				expect(payload.exception.type).toBe("Wheels.ViewNotFound");
				expect(payload.exception.message).toInclude("show");
				expect(payload.suggestedAction).toInclude("app/views/users/show.cfm");
				expect(payload.source).toBe("wheels-error-page");
			});

			it("serializes to JSON that round-trips the exception fields", () => {
				var builder = CreateObject("component", "wheels.events.onerror.ErrorCopyPayload");
				var json = builder.toJson({
					type = "Wheels.RouteNotFound",
					message = "No route matched",
					extendedInfo = "Check config/routes.cfm",
					tagContext = []
				});
				expect(IsJSON(json)).toBeTrue();
				var data = DeserializeJSON(json);
				expect(data.exception.type).toBe("Wheels.RouteNotFound");
				expect(data.exception.message).toBe("No route matched");
				expect(data.suggestedAction).toBe("Check config/routes.cfm");
			});

			it("classifies app, framework, library, and plugin frames", () => {
				var builder = CreateObject("component", "wheels.events.onerror.ErrorCopyPayload");
				var frames = builder.classifyFrames([
					{template = "/srv/app/models/User.cfc", line = 10},
					{template = "/srv/vendor/wheels/Model.cfc", line = 20},
					{template = "/srv/vendor/testbox/system/TestBox.cfc", line = 30},
					{template = "/srv/plugins/sentry/Sentry.cfc", line = 40}
				]);
				expect(ArrayLen(frames)).toBe(4);
				expect(frames[1].type).toBe("app");
				expect(frames[2].type).toBe("framework");
				expect(frames[3].type).toBe("library");
				expect(frames[4].type).toBe("plugin");
				expect(frames[2].line).toBe(20);
			});

			it("classifies Windows-style vendor wheels paths as framework", () => {
				var builder = CreateObject("component", "wheels.events.onerror.ErrorCopyPayload");
				var winPath = Replace("C:/sites/demo/vendor/wheels/Dispatch.cfc", "/", Chr(92), "all");
				var frames = builder.classifyFrames([{template = winPath, line = 8}]);
				expect(ArrayLen(frames)).toBe(1);
				expect(frames[1].type).toBe("framework");
			});

			it("classifies public index.cfm and Application.cfc as framework", () => {
				var builder = CreateObject("component", "wheels.events.onerror.ErrorCopyPayload");
				var frames = builder.classifyFrames([
					{template = "/srv/public/index.cfm", line = 1},
					{template = "/srv/public/Application.cfc", line = 12}
				]);
				expect(frames[1].type).toBe("framework");
				expect(frames[2].type).toBe("framework");
			});

			it("picks the first app frame after the innermost throw site as location", () => {
				var builder = CreateObject("component", "wheels.events.onerror.ErrorCopyPayload");
				var payload = builder.build({
					type = "Wheels.TestError",
					message = "location-pick",
					tagContext = [
						{template = "/srv/vendor/wheels/Global.cfc", line = 99},
						{template = "/srv/app/controllers/Users.cfc", line = 3},
						{template = "/srv/vendor/wheels/Dispatch.cfc", line = 40}
					]
				});
				expect(payload.location.line).toBe(3);
				expect(payload.location.type).toBe("app");
				expect(payload.location.template).toInclude("Users.cfc");
			});

			it("reads a source snippet around the error line", () => {
				var builder = CreateObject("component", "wheels.events.onerror.ErrorCopyPayload");
				var specPath = GetCurrentTemplatePath();
				var snippet = builder.readSnippet(templatePath = specPath, lineNumber = 1, contextLines = 2);
				expect(snippet.errorLine).toBe(1);
				expect(snippet.startLine).toBe(1);
				expect(ArrayLen(snippet.lines)).toBeGT(0);
				expect(snippet.lines[1].highlight).toBeTrue();
				expect(snippet.lines[1].code).toInclude("component");
			});

			it("returns an empty snippet when the file cannot be read", () => {
				var builder = CreateObject("component", "wheels.events.onerror.ErrorCopyPayload");
				var snippet = builder.readSnippet(
					templatePath = "/tmp/wheels-error-copy-missing-file.cfm",
					lineNumber = 10
				);
				expect(ArrayLen(snippet.lines)).toBe(0);
				expect(snippet.startLine).toBe(0);
			});

			it("survives a missing tagContext", () => {
				var builder = CreateObject("component", "wheels.events.onerror.ErrorCopyPayload");
				var payload = builder.build({
					type = "Wheels.TestError",
					message = "no-stack"
				});
				expect(payload.exception.type).toBe("Wheels.TestError");
				expect(payload.stack).toBeArray();
				expect(ArrayLen(payload.stack)).toBe(0);
				expect(StructIsEmpty(payload.location)).toBeTrue();
			});

		});

		describe("wheelserror.cfm Copy control", () => {

			it("renders a Copy button and a JSON payload script", () => {
				var specPath = GetCurrentTemplatePath();
				var wheelsError = {
					type = "Wheels.TestError",
					message = "copy-button-marker-message",
					extendedInfo = "copy-button-suggested-action",
					tagContext = [
						{template = specPath, line = 1},
						{template = specPath, line = 2}
					]
				};
				var actual = application.wo.$includeAndReturnOutput(
					$template = "/wheels/events/onerror/wheelserror.cfm",
					wheelsError = wheelsError
				);
				expect(actual).toInclude("wheels-copy-error");
				expect(actual).toInclude("wheels-error-copy-payload");
				expect(actual).toInclude("Copy");
				expect(actual).toInclude("copy-button-marker-message");
				expect(actual).toInclude("Wheels.TestError");
				expect(actual).toInclude("copy-button-suggested-action");
				expect(actual).toInclude("wheelsCopyErrorPayload");
				expect(actual).toInclude("navigator.clipboard");
				expect(actual).toInclude("wheels-error-page");
			});

			it("keeps the Copy control when tagContext is empty", () => {
				var actual = application.wo.$includeAndReturnOutput(
					$template = "/wheels/events/onerror/wheelserror.cfm",
					wheelsError = {
						type = "Wheels.EmptyStack",
						message = "empty-stack-copy",
						tagContext = []
					}
				);
				expect(actual).toInclude("wheels-copy-error");
				expect(actual).toInclude("empty-stack-copy");
			});

		});

	}

}
