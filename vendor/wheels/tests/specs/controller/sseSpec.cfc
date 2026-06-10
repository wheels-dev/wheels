/**
 * Tests for Server-Sent Events (SSE) controller support.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("SSE Event Formatting", function() {

			beforeEach(function() {
				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);
			});

			it("renderSSE sets the response with SSE formatted data", function() {
				_controller.renderSSE(data = "hello world");
				local.response = _controller.response();
				expect(local.response).toInclude("data: hello world");
			});

			it("renderSSE includes event type when specified", function() {
				_controller.renderSSE(data = "payload", event = "update");
				local.response = _controller.response();
				expect(local.response).toInclude("event: update");
				expect(local.response).toInclude("data: payload");
			});

			it("renderSSE includes event ID when specified", function() {
				_controller.renderSSE(data = "payload", id = "msg-123");
				local.response = _controller.response();
				expect(local.response).toInclude("id: msg-123");
			});

			it("renderSSE includes retry interval when specified", function() {
				_controller.renderSSE(data = "payload", retry = 5000);
				local.response = _controller.response();
				expect(local.response).toInclude("retry: 5000");
			});

			it("renderSSE includes all fields together", function() {
				_controller.renderSSE(data = "test data", event = "notification", id = "42", retry = 3000);
				local.response = _controller.response();
				expect(local.response).toInclude("id: 42");
				expect(local.response).toInclude("event: notification");
				expect(local.response).toInclude("retry: 3000");
				expect(local.response).toInclude("data: test data");
			});

			it("renderSSE terminates event with double newline", function() {
				_controller.renderSSE(data = "test");
				local.response = _controller.response();
				// SSE events must end with \n\n
				expect(Right(local.response, 2)).toBe(Chr(10) & Chr(10));
			});

			it("renderSSE handles multiline data correctly", function() {
				local.multiline = "line one" & Chr(10) & "line two" & Chr(10) & "line three";
				_controller.renderSSE(data = local.multiline);
				local.response = _controller.response();
				expect(local.response).toInclude("data: line one");
				expect(local.response).toInclude("data: line two");
				expect(local.response).toInclude("data: line three");
			});

			it("renderSSE handles JSON data", function() {
				local.jsonData = SerializeJSON({message: "hello", count: 5});
				_controller.renderSSE(data = local.jsonData, event = "data");
				local.response = _controller.response();
				expect(local.response).toInclude("event: data");
				expect(local.response).toInclude("data: ");
			});
		});

		describe("SSE Request Detection", function() {

			beforeEach(function() {
				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);
			});

			it("isSSERequest returns boolean", function() {
				local.result = _controller.isSSERequest();
				expect(local.result).toBeBoolean();
			});
		});

		describe("$formatSSEEvent internal method", function() {

			beforeEach(function() {
				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);
			});

			it("formats data-only event", function() {
				local.result = _controller.$formatSSEEvent(data = "simple message");
				expect(local.result).toBe("data: simple message" & Chr(10) & Chr(10));
			});

			it("formats event with type", function() {
				local.result = _controller.$formatSSEEvent(data = "msg", event = "chat");
				expect(local.result).toInclude("event: chat");
				expect(local.result).toInclude("data: msg");
			});

			it("formats event with all fields in correct order", function() {
				local.result = _controller.$formatSSEEvent(data = "msg", event = "update", id = "1", retry = 1000);
				// ID should come before event, event before retry, retry before data
				local.idPos = FindNoCase("id:", local.result);
				local.eventPos = FindNoCase("event:", local.result);
				local.retryPos = FindNoCase("retry:", local.result);
				local.dataPos = FindNoCase("data:", local.result);

				expect(local.idPos).toBeGT(0);
				expect(local.eventPos).toBeGT(local.idPos);
				expect(local.retryPos).toBeGT(local.eventPos);
				expect(local.dataPos).toBeGT(local.retryPos);
			});

			it("does not include empty optional fields", function() {
				local.result = _controller.$formatSSEEvent(data = "test");
				expect(local.result).notToInclude("id:");
				expect(local.result).notToInclude("event:");
				expect(local.result).notToInclude("retry:");
			});

			it("handles empty data string", function() {
				local.result = _controller.$formatSSEEvent(data = "");
				expect(local.result).toInclude("data: ");
			});

			it("preserves blank lines in multi-line data", function() {
				local.input = "line one" & Chr(10) & Chr(10) & "line two";
				local.result = _controller.$formatSSEEvent(data = local.input);
				// The blank line must survive as an empty data: field so the client
				// reconstructs "line one\n\nline two" instead of "line one\nline two"
				expect(local.result).toBe(
					"data: line one" & Chr(10) & "data: " & Chr(10) & "data: line two" & Chr(10) & Chr(10)
				);
			});
		});

		describe("SSE Newline Injection Prevention", function() {

			beforeEach(function() {
				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);
			});

			it("strips newlines from id field to prevent field injection", function() {
				local.result = _controller.$formatSSEEvent(data = "test", id = "123" & Chr(10) & "event: malicious");
				expect(local.result).toInclude("id: 123event: malicious");
				// No line should start with "event:" — the injected text is harmlessly concatenated in the id value
				local.lines = ListToArray(local.result, Chr(10));
				for (local.line in local.lines) {
					if (Left(Trim(local.line), 6) == "event:") {
						fail("Injected event: field found on its own line");
					}
				}
			});

			it("strips carriage returns from id field", function() {
				local.result = _controller.$formatSSEEvent(data = "test", id = "123" & Chr(13) & "event: malicious");
				// CR stripped, so the id line contains the injected text harmlessly concatenated
				expect(local.result).toInclude("id: 123event: malicious");
				// No CR characters should remain in output
				expect(local.result).notToInclude(Chr(13));
			});

			it("strips newlines from event field to prevent field injection", function() {
				local.result = _controller.$formatSSEEvent(data = "test", event = "update" & Chr(10) & "id: spoofed");
				expect(local.result).toInclude("event: updateid: spoofed");
				// The injected id: should not be on its own line
				local.lines = ListToArray(local.result, Chr(10));
				for (local.line in local.lines) {
					if (Left(local.line, 3) == "id:") {
						fail("Injected id: field found on its own line");
					}
				}
			});

			it("strips carriage returns from event field", function() {
				local.result = _controller.$formatSSEEvent(data = "test", event = "update" & Chr(13) & "data: injected");
				expect(local.result).notToInclude(Chr(13));
			});

			it("normalizes CRLF in data to separate data lines", function() {
				local.input = "line1" & Chr(13) & Chr(10) & "line2";
				local.result = _controller.$formatSSEEvent(data = local.input);
				expect(local.result).toInclude("data: line1");
				expect(local.result).toInclude("data: line2");
			});

			it("normalizes lone CR in data to separate data lines", function() {
				local.input = "line1" & Chr(13) & "line2";
				local.result = _controller.$formatSSEEvent(data = local.input);
				expect(local.result).toInclude("data: line1");
				expect(local.result).toInclude("data: line2");
			});

			it("prevents CR-based field injection in data", function() {
				local.input = "safe data" & Chr(13) & "event: malicious";
				local.result = _controller.$formatSSEEvent(data = local.input);
				// CR should be normalized to LF, so "event: malicious" becomes a data: line
				expect(local.result).toInclude("data: event: malicious");
			});
		});
	}
}
