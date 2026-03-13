/**
 * Channel subscription mixin for Wheels controllers.
 *
 * Builds on top of the existing SSE primitives (sse.cfc) to provide
 * channel-based pub/sub via Server-Sent Events. Auto-loaded by
 * Controller.cfc's $integrateComponents("wheels.controller").
 *
 * Usage:
 *   function notifications() {
 *     subscribeToChannel(
 *       channel="user.#params.userId#",
 *       events="notification,alert"
 *     );
 *   }
 */
component {

	/**
	 * Subscribe to a channel and stream events to the client via SSE.
	 * Opens a long-lived SSE connection that delivers matching events
	 * until the client disconnects or the timeout is reached.
	 *
	 * For the "memory" adapter, subscribes to the in-memory Channel
	 * engine and buffers events for delivery. For the "database" adapter,
	 * polls the _wheels_events table at regular intervals.
	 *
	 * @channel The channel name to subscribe to (e.g. "user.42").
	 * @events Comma-delimited list of event types to filter. Empty = all events.
	 * @lastEventId Resume from this event ID. Auto-detected from Last-Event-ID header if empty.
	 * @adapter "memory" (default) or "database".
	 * @pollInterval Seconds between polls for database adapter (default 2).
	 * @timeout Maximum connection duration in seconds (default 300 = 5 minutes).
	 * @heartbeatInterval Seconds between keep-alive pings (default 15).
	 */
	public void function subscribeToChannel(
		required string channel,
		string events = "",
		string lastEventId = "",
		string adapter = "",
		numeric pollInterval = 2,
		numeric timeout = 300,
		numeric heartbeatInterval = 15
	) {
		// Auto-detect Last-Event-ID from request header
		if (!Len(arguments.lastEventId)) {
			try {
				local.headers = GetHTTPRequestData().headers;
				if (StructKeyExists(local.headers, "Last-Event-ID")) {
					arguments.lastEventId = local.headers["Last-Event-ID"];
				}
			} catch (any e) {
				// Ignore header detection errors
			}
		}

		// Resolve adapter type
		local.adapterType = arguments.adapter;
		if (!Len(local.adapterType)) {
			if (StructKeyExists(application, "wheels") && StructKeyExists(application.wheels, "channelAdapter")) {
				local.adapterType = application.wheels.channelAdapter;
			} else {
				local.adapterType = "memory";
			}
		}

		// Parse event filter list
		local.eventFilter = [];
		if (Len(arguments.events)) {
			local.eventFilter = ListToArray(arguments.events);
		}

		if (local.adapterType == "database") {
			$subscribeDatabase(
				channel = arguments.channel,
				eventFilter = local.eventFilter,
				lastEventId = arguments.lastEventId,
				pollInterval = arguments.pollInterval,
				timeout = arguments.timeout,
				heartbeatInterval = arguments.heartbeatInterval
			);
		} else {
			$subscribeMemory(
				channel = arguments.channel,
				eventFilter = local.eventFilter,
				lastEventId = arguments.lastEventId,
				timeout = arguments.timeout,
				heartbeatInterval = arguments.heartbeatInterval
			);
		}
	}

	/**
	 * Generate a <script> tag that creates an EventSource for a channel.
	 * Convenience view helper for quickly wiring up SSE in templates.
	 *
	 * @channel The channel name.
	 * @route Named route for the SSE endpoint.
	 * @controller Controller name (used with action if no route).
	 * @action Action name (default "stream").
	 * @events Comma-delimited list of event types.
	 * @return HTML script tag string.
	 */
	public string function channelSSETag(
		required string channel,
		string route = "",
		string controller = "",
		string action = "stream",
		string events = ""
	) {
		// Build URL
		if (Len(arguments.route)) {
			local.url = urlFor(route = arguments.route);
		} else if (Len(arguments.controller)) {
			local.url = urlFor(controller = arguments.controller, action = arguments.action);
		} else {
			throw(
				type = "Wheels.Channel.MissingEndpoint",
				message = "channelSSETag requires either a 'route' or 'controller' argument."
			);
		}

		// Build params
		local.url &= (Find("?", local.url) ? "&" : "?") & "channel=" & EncodeForURL(arguments.channel);
		if (Len(arguments.events)) {
			local.url &= "&events=" & EncodeForURL(arguments.events);
		}

		return "<script>
(function(){
	var src = new EventSource('#JSStringFormat(local.url)#');
	src.onmessage = function(e) {
		document.dispatchEvent(new CustomEvent('wheels:sse', {detail: {data: e.data, event: e.type, id: e.lastEventId}}));
	};
})();
</script>";
	}

	/**
	 * Internal: Memory-adapter subscription loop.
	 * Subscribes to the Channel singleton, buffers events in a synchronized
	 * array, and streams them to the client via SSE.
	 */
	private void function $subscribeMemory(
		required string channel,
		required array eventFilter,
		required string lastEventId,
		required numeric timeout,
		required numeric heartbeatInterval
	) {
		local.writer = initSSEStream();
		local.engine = $getChannelEngine("memory");

		// Thread-safe event buffer using a synchronized list
		local.buffer = CreateObject("java", "java.util.Collections").synchronizedList(
			CreateObject("java", "java.util.ArrayList").init()
		);

		// Subscribe with a callback that buffers events
		local.subscriberId = local.engine.subscribe(
			channel = arguments.channel,
			callback = function(event) {
				// Filter by event type if specified
				if (ArrayLen(eventFilter) && !ArrayFind(eventFilter, event.event)) {
					return;
				}
				buffer.add(event);
			}
		);

		try {
			local.startTime = GetTickCount() / 1000;
			local.lastHeartbeat = local.startTime;

			while (true) {
				// Check timeout
				local.now = GetTickCount() / 1000;
				if (local.now - local.startTime > arguments.timeout) {
					break;
				}

				// Drain buffer and send events
				local.size = local.buffer.size();
				if (local.size > 0) {
					// Snapshot and clear
					local.events = [];
					for (local.i = 1; local.i <= local.size; local.i++) {
						ArrayAppend(local.events, local.buffer.get(local.i - 1));
					}
					local.buffer.clear();

					for (local.evt in local.events) {
						sendSSEEvent(
							writer = local.writer,
							data = local.evt.data,
							event = local.evt.event,
							id = local.evt.id
						);
					}
					local.lastHeartbeat = local.now;
				}

				// Heartbeat
				if (local.now - local.lastHeartbeat > arguments.heartbeatInterval) {
					sendSSEComment(writer = local.writer);
					local.lastHeartbeat = local.now;
				}

				// Check client disconnect
				if (local.writer.checkError()) {
					break;
				}

				sleep(500);
			}
		} finally {
			local.engine.unsubscribe(arguments.channel, local.subscriberId);
			closeSSEStream(local.writer);
		}
	}

	/**
	 * Internal: Database-adapter subscription loop.
	 * Polls the DatabaseAdapter at regular intervals and streams
	 * matching events to the client via SSE.
	 */
	private void function $subscribeDatabase(
		required string channel,
		required array eventFilter,
		required string lastEventId,
		required numeric pollInterval,
		required numeric timeout,
		required numeric heartbeatInterval
	) {
		local.writer = initSSEStream();
		local.dbAdapter = $getChannelEngine("database");
		local.currentLastId = arguments.lastEventId;

		try {
			local.startTime = GetTickCount() / 1000;
			local.lastHeartbeat = local.startTime;

			while (true) {
				// Check timeout
				local.now = GetTickCount() / 1000;
				if (local.now - local.startTime > arguments.timeout) {
					break;
				}

				// Poll for events
				local.events = local.dbAdapter.poll(
					channel = arguments.channel,
					lastEventId = local.currentLastId
				);

				if (local.events.recordCount > 0) {
					for (local.row = 1; local.row <= local.events.recordCount; local.row++) {
						// Filter by event type if specified
						if (ArrayLen(arguments.eventFilter) && !ArrayFind(arguments.eventFilter, local.events.event[local.row])) {
							continue;
						}

						sendSSEEvent(
							writer = local.writer,
							data = local.events.data[local.row],
							event = local.events.event[local.row],
							id = local.events.id[local.row]
						);
						local.currentLastId = local.events.id[local.row];
					}
					local.lastHeartbeat = local.now;
				}

				// Heartbeat
				if (local.now - local.lastHeartbeat > arguments.heartbeatInterval) {
					sendSSEComment(writer = local.writer);
					local.lastHeartbeat = local.now;
				}

				// Check client disconnect
				if (local.writer.checkError()) {
					break;
				}

				sleep(arguments.pollInterval * 1000);
			}
		} finally {
			closeSSEStream(local.writer);
		}
	}

}
