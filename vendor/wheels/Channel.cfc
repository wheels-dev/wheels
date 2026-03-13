/**
 * Core in-memory pub/sub engine for Wheels SSE channels.
 *
 * Application-scoped singleton managing channel subscriptions with
 * ConcurrentHashMap for thread safety. Used by the global publish()
 * function and the subscribeToChannel() controller mixin.
 *
 * Usage:
 *   // Subscribe (typically done by subscribeToChannel controller mixin)
 *   var engine = application.wheels.channelEngine;
 *   var subId = engine.subscribe("user.42", function(event) {
 *     // handle event
 *   });
 *
 *   // Publish from anywhere
 *   engine.publish(channel="user.42", event="notification", data='{"title":"Hello"}');
 *
 *   // Unsubscribe
 *   engine.unsubscribe("user.42", subId);
 */
component {

	/**
	 * Initialize the channel engine with ConcurrentHashMap stores.
	 */
	public Channel function init() {
		// channel -> ConcurrentHashMap of subscriberId -> {callback, createdAt}
		variables.channels = CreateObject("java", "java.util.concurrent.ConcurrentHashMap").init();
		return this;
	}

	/**
	 * Subscribe to a channel with a callback function.
	 *
	 * @channel The channel name to subscribe to (e.g. "user.42").
	 * @callback A closure/function that receives a struct {id, channel, event, data, timestamp}.
	 * @id Optional subscriber ID. If not provided, a UUID is generated.
	 * @return The subscriber ID.
	 */
	public string function subscribe(
		required string channel,
		required any callback,
		string id = CreateUUID()
	) {
		// Ensure channel map exists (putIfAbsent is atomic)
		variables.channels.putIfAbsent(
			arguments.channel,
			CreateObject("java", "java.util.concurrent.ConcurrentHashMap").init()
		);

		local.subscribers = variables.channels.get(arguments.channel);
		local.subscribers.put(arguments.id, {
			callback: arguments.callback,
			createdAt: Now()
		});

		return arguments.id;
	}

	/**
	 * Publish an event to all subscribers on a channel.
	 * Per-subscriber error isolation ensures one failing callback doesn't affect others.
	 *
	 * @channel The channel name to publish to.
	 * @event The event type (e.g. "notification", "update").
	 * @data The event data as a string (typically JSON).
	 * @id Optional event ID. If not provided, a UUID is generated.
	 * @return Struct with {id, channel, event, subscriberCount, timestamp}.
	 */
	public struct function publish(
		required string channel,
		required string event,
		required string data,
		string id = CreateUUID()
	) {
		local.timestamp = Now();
		local.eventPayload = {
			id: arguments.id,
			channel: arguments.channel,
			event: arguments.event,
			data: arguments.data,
			timestamp: local.timestamp
		};

		local.subscriberCount = 0;
		local.subscribers = variables.channels.get(arguments.channel);

		if (!IsNull(local.subscribers)) {
			// Snapshot iteration — safe even if subscribers are added/removed during iteration
			local.entries = local.subscribers.entrySet().toArray();
			for (local.entry in local.entries) {
				local.subscriberCount++;
				try {
					local.entry.getValue().callback(local.eventPayload);
				} catch (any e) {
					writeLog(
						text="Channel subscriber error on [#arguments.channel#]: #e.message#",
						type="error",
						file="wheels_channels"
					);
				}
			}
		}

		return {
			id: arguments.id,
			channel: arguments.channel,
			event: arguments.event,
			subscriberCount: local.subscriberCount,
			timestamp: local.timestamp
		};
	}

	/**
	 * Unsubscribe from a channel.
	 *
	 * @channel The channel name.
	 * @subscriberId The subscriber ID returned by subscribe().
	 * @return True if the subscriber was found and removed.
	 */
	public boolean function unsubscribe(required string channel, required string subscriberId) {
		local.subscribers = variables.channels.get(arguments.channel);
		if (IsNull(local.subscribers)) {
			return false;
		}
		local.removed = local.subscribers.remove(arguments.subscriberId);
		return !IsNull(local.removed);
	}

	/**
	 * Get the number of subscribers on a channel.
	 *
	 * @channel The channel name.
	 * @return The subscriber count.
	 */
	public numeric function subscriberCount(required string channel) {
		local.subscribers = variables.channels.get(arguments.channel);
		if (IsNull(local.subscribers)) {
			return 0;
		}
		return local.subscribers.size();
	}

	/**
	 * Get all active channel names.
	 *
	 * @return Array of channel name strings.
	 */
	public array function getChannels() {
		local.result = [];
		local.keys = variables.channels.keySet().toArray();
		for (local.key in local.keys) {
			ArrayAppend(local.result, local.key);
		}
		return local.result;
	}

	/**
	 * Remove a channel and all its subscribers.
	 *
	 * @channel The channel name to remove.
	 */
	public void function removeChannel(required string channel) {
		variables.channels.remove(arguments.channel);
	}

}
