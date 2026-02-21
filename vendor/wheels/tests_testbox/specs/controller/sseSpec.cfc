/**
 * Tests for Server-Sent Events (SSE) controller support.
 */
component extends="wheels.Testbox" {

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
		});
	}
}
