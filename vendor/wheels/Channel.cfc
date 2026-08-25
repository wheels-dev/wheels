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
		variables.eventLog = CreateObject("java", "java.util.concurrent.ConcurrentHashMap").init();
		variables.maxEventLogSize = 100;
		return this;
	}

	public void function $assertChannelName(required string channel) {
		if (!Len(Trim(arguments.channel))) {
			throw(type = "Wheels.Channel.InvalidName", message = "Channel name cannot be empty.");
		}
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
		$assertChannelName(arguments.channel);
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
		$assertChannelName(arguments.channel);
		local.timestamp = Now();
		local.eventPayload = {
			id: arguments.id,
			channel: arguments.channel,
			event: arguments.event,
			data: arguments.data,
			timestamp: local.timestamp
		};
		$appendEventLog(arguments.channel, local.eventPayload);

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

		// Prune the per-channel map once its last subscriber leaves so per-entity
		// channel names (e.g. "user.42") don't accumulate empty maps in this
		// app-scoped singleton for the application lifetime. The atomic two-argument
		// remove(key, value) only removes the entry if the channel still maps to this
		// same subscriber map, so it never discards a replacement map created by a
		// concurrent subscribe(). Known (tiny) race: a subscriber that lands in this
		// exact map between the isEmpty() check and the remove() is orphaned and
		// receives no events until its connection times out and the client
		// re-subscribes.
		if (local.subscribers.isEmpty()) {
			variables.channels.remove(arguments.channel, local.subscribers);
		}

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
		variables.eventLog.remove(arguments.channel);
	}

	/**
	 * Return retained events on a channel after lastEventId.
	 * If lastEventId is not in the retained window, return the retained tail.
	 */
	public array function replay(required string channel, required string lastEventId) {
		$assertChannelName(arguments.channel);
		local.out = [];
		local.log = variables.eventLog.get(arguments.channel);
		if (IsNull(local.log)) {
			return local.out;
		}
		local.snapshot = local.log.toArray();
		local.seen = false;
		for (local.evt in local.snapshot) {
			if (local.seen) {
				ArrayAppend(local.out, local.evt);
			}
			if (local.evt.id == arguments.lastEventId) {
				local.seen = true;
			}
		}
		if (!local.seen) {
			return local.snapshot;
		}
		return local.out;
	}

	private void function $appendEventLog(required string channel, required struct eventPayload) {
		variables.eventLog.putIfAbsent(
			arguments.channel,
			CreateObject("java", "java.util.concurrent.ConcurrentLinkedQueue").init()
		);
		local.log = variables.eventLog.get(arguments.channel);
		local.log.offer(arguments.eventPayload);
		while (local.log.size() > variables.maxEventLogSize) {
			local.log.poll();
		}
	}

}
