/**
 * Server-Sent Events (SSE) support for Wheels controllers.
 *
 * Provides methods for sending SSE-formatted responses to clients.
 * Since CFML uses a request-response model, this implements SSE as
 * single-response endpoints (ideal for polling-based SSE or one-shot events).
 *
 * For long-lived connections, use initSSEStream() which bypasses the
 * normal Wheels rendering pipeline and writes directly to the response.
 *
 * Usage in a controller:
 *
 *   // Single event response (client reconnects to get next event)
 *   function updates() {
 *     var data = model("Notification").findAll(where="userId=#params.userId# AND sent=0");
 *     renderSSE(data=SerializeJSON(data), event="notifications");
 *   }
 *
 *   // Streaming multiple events (long-lived connection)
 *   function stream() {
 *     var writer = initSSEStream();
 *     var notifications = model("Notification").findAll(where="read=0");
 *     for (var n in notifications) {
 *       sendSSEEvent(writer=writer, data=SerializeJSON(n), event="notification", id=n.id);
 *     }
 *     closeSSEStream(writer);
 *   }
 */
component {

	/**
	 * Render a single SSE event as the controller response.
	 * This sets appropriate headers and formats the response as an SSE event.
	 * The client should use EventSource to connect and will receive this single event.
	 *
	 * @data The event data to send (string). Will be sent as-is.
	 * @event Optional event type name. Client can listen for specific event types.
	 * @id Optional event ID. Client sends Last-Event-ID header on reconnect.
	 * @retry Optional reconnection time in milliseconds. Tells client how long to wait before reconnecting.
	 */
	public void function renderSSE(
		required string data,
		string event = "",
		string id = "",
		numeric retry = 0
	) {
		// Set SSE headers
		$header(name = "Content-Type", value = "text/event-stream");
		$header(name = "Cache-Control", value = "no-cache");
		$header(name = "Connection", value = "keep-alive");
		$header(name = "X-Accel-Buffering", value = "no");

		// Build the SSE event string
		local.sseText = $formatSSEEvent(argumentCollection = arguments);

		// Render the SSE text as the response
		renderText(text = local.sseText);
	}

	/**
	 * Initialize a streaming SSE connection that bypasses the normal Wheels rendering pipeline.
	 * Returns a writer object that can be used with sendSSEEvent() and closeSSEStream().
	 * This enables sending multiple events over a single connection.
	 *
	 * Note: This bypasses layouts and after-filters. Use for true streaming endpoints only.
	 */
	public any function initSSEStream() {
		// Get the underlying response object
		if (StructKeyExists(server, "boxlang")) {
			local.response = GetPageContext();
		} else if (StructKeyExists(server, "lucee")) {
			local.response = GetPageContext().getResponse();
		} else {
			local.response = GetPageContext().getFusionContext().getResponse();
		}

		// Set SSE headers
		local.response.setContentType("text/event-stream");
		local.response.setHeader("Cache-Control", "no-cache");
		local.response.setHeader("Connection", "keep-alive");
		local.response.setHeader("X-Accel-Buffering", "no");

		// Get the output writer
		local.writer = local.response.getWriter();

		// Mark that we've handled the response directly
		renderNothing();

		return local.writer;
	}

	/**
	 * Send an SSE event through a streaming writer obtained from initSSEStream().
	 *
	 * @writer The writer object returned by initSSEStream().
	 * @data The event data to send.
	 * @event Optional event type name.
	 * @id Optional event ID.
	 * @retry Optional reconnection time in milliseconds.
	 */
	public void function sendSSEEvent(
		required any writer,
		required string data,
		string event = "",
		string id = "",
		numeric retry = 0
	) {
		local.sseText = $formatSSEEvent(
			data = arguments.data,
			event = arguments.event,
			id = arguments.id,
			retry = arguments.retry
		);
		arguments.writer.write(local.sseText);
		arguments.writer.flush();
	}

	/**
	 * Send an SSE comment (keep-alive ping) through a streaming writer.
	 *
	 * @writer The writer object returned by initSSEStream().
	 * @comment Optional comment text.
	 */
	public void function sendSSEComment(required any writer, string comment = "ping") {
		arguments.writer.write(": #arguments.comment##Chr(10)##Chr(10)#");
		arguments.writer.flush();
	}

	/**
	 * Close an SSE streaming connection.
	 *
	 * @writer The writer object returned by initSSEStream().
	 */
	public void function closeSSEStream(required any writer) {
		try {
			arguments.writer.flush();
			arguments.writer.close();
		} catch (any e) {
			// Client may have already disconnected
		}
	}

	/**
	 * Check if the current request is from an EventSource client.
	 * Useful for conditionally rendering SSE vs HTML responses.
	 */
	public boolean function isSSERequest() {
		local.accept = "";
		try {
			local.accept = GetHTTPRequestData().headers["Accept"] ?: "";
		} catch (any e) {
			// Ignore
		}
		return FindNoCase("text/event-stream", local.accept) > 0;
	}

	/**
	 * Internal: Format data as an SSE event string.
	 *
	 * SSE format spec:
	 *   id: <id>\n
	 *   event: <type>\n
	 *   retry: <ms>\n
	 *   data: <line1>\n
	 *   data: <line2>\n
	 *   \n
	 */
	private string function $formatSSEEvent(
		required string data,
		string event = "",
		string id = "",
		numeric retry = 0
	) {
		local.lines = [];

		// Event ID
		if (Len(arguments.id)) {
			ArrayAppend(local.lines, "id: #arguments.id#");
		}

		// Event type
		if (Len(arguments.event)) {
			ArrayAppend(local.lines, "event: #arguments.event#");
		}

		// Retry interval
		if (arguments.retry > 0) {
			ArrayAppend(local.lines, "retry: #arguments.retry#");
		}

		// Data lines (each line of data gets its own "data:" prefix per SSE spec)
		if (Len(arguments.data)) {
			local.dataLines = ListToArray(arguments.data, Chr(10));
			for (local.line in local.dataLines) {
				ArrayAppend(local.lines, "data: #local.line#");
			}
		} else {
			ArrayAppend(local.lines, "data: ");
		}

		// End with double newline to terminate the event
		return ArrayToList(local.lines, Chr(10)) & Chr(10) & Chr(10);
	}
}
