/**
 * Core in-memory pub/sub engine for Wheels SSE channels.
 *
 * Application-scoped singleton managing channel subscriptions. Stores are
 * plain CFML structs and arrays guarded by a named lock, so the engine is
 * engine-agnostic (no JVM classes) and runs on RustCFML too. Used by the
 * global publish() function and the subscribeToChannel() controller mixin.
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
	 * Initialize the channel engine with plain CFML stores.
	 */
	public Channel function init() {
		// channel -> struct of subscriberId -> {callback, createdAt}
		variables.channels = {};
		// channel -> array of retained event payloads (capped tail)
		variables.eventLog = {};
		variables.maxEventLogSize = 100;
		variables.lockName = "wheelsChannelEngine";
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
		lock name="#variables.lockName#" type="exclusive" timeout="10" {
			if (!StructKeyExists(variables.channels, arguments.channel)) {
				variables.channels[arguments.channel] = {};
			}
			variables.channels[arguments.channel][arguments.id] = {
				callback: arguments.callback,
				createdAt: Now()
			};
		}

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

		// Snapshot the callbacks under the lock; invoke them AFTER the lock
		// is released so a callback that publishes or subscribes again cannot
		// deadlock on a non-reentrant exclusive named lock.
		local.callbacks = [];
		lock name="#variables.lockName#" type="exclusive" timeout="10" {
			if (!StructKeyExists(variables.eventLog, arguments.channel)) {
				variables.eventLog[arguments.channel] = [];
			}
			ArrayAppend(variables.eventLog[arguments.channel], local.eventPayload);
			while (ArrayLen(variables.eventLog[arguments.channel]) > variables.maxEventLogSize) {
				ArrayDeleteAt(variables.eventLog[arguments.channel], 1);
			}

			if (StructKeyExists(variables.channels, arguments.channel) && StructCount(variables.channels[arguments.channel])) {
				local.subIds = ListToArray(StructKeyList(variables.channels[arguments.channel]));
				for (local.subId in local.subIds) {
					ArrayAppend(local.callbacks, variables.channels[arguments.channel][local.subId].callback);
				}
			}
		}

		local.subscriberCount = ArrayLen(local.callbacks);
		for (local.callback in local.callbacks) {
			try {
				local.callback(local.eventPayload);
			} catch (any e) {
				writeLog(
					text="Channel subscriber error on [#arguments.channel#]: #e.message#",
					type="error",
					file="wheels_channels"
				);
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
		local.removed = false;
		lock name="#variables.lockName#" type="exclusive" timeout="10" {
			if (StructKeyExists(variables.channels, arguments.channel)) {
				local.removed = StructKeyExists(variables.channels[arguments.channel], arguments.subscriberId);
				StructDelete(variables.channels[arguments.channel], arguments.subscriberId);
				// Prune the per-channel struct once its last subscriber leaves
				// so per-entity channel names (e.g. "user.42") don't accumulate
				// empty structs in this app-scoped singleton for the application
				// lifetime.
				if (StructIsEmpty(variables.channels[arguments.channel])) {
					StructDelete(variables.channels, arguments.channel);
				}
			}
		}

		return local.removed;
	}

	/**
	 * Get the number of subscribers on a channel.
	 *
	 * @channel The channel name.
	 * @return The subscriber count.
	 */
	public numeric function subscriberCount(required string channel) {
		local.count = 0;
		lock name="#variables.lockName#" type="exclusive" timeout="10" {
			if (StructKeyExists(variables.channels, arguments.channel)) {
				local.count = StructCount(variables.channels[arguments.channel]);
			}
		}
		return local.count;
	}

	/**
	 * Get all active channel names.
	 *
	 * @return Array of channel name strings.
	 */
	public array function getChannels() {
		local.result = [];
		lock name="#variables.lockName#" type="exclusive" timeout="10" {
			local.channelNames = StructKeyList(variables.channels);
			if (Len(local.channelNames)) {
				local.result = ListToArray(local.channelNames);
			}
		}
		return local.result;
	}

	/**
	 * Remove a channel and all its subscribers.
	 *
	 * @channel The channel name to remove.
	 */
	public void function removeChannel(required string channel) {
		lock name="#variables.lockName#" type="exclusive" timeout="10" {
			StructDelete(variables.channels, arguments.channel);
			StructDelete(variables.eventLog, arguments.channel);
		}
	}

	/**
	 * Return retained events on a channel after lastEventId.
	 * If lastEventId is not in the retained window, return the retained tail.
	 */
	public array function replay(required string channel, required string lastEventId) {
		$assertChannelName(arguments.channel);
		local.rv = [];
		lock name="#variables.lockName#" type="exclusive" timeout="10" {
			if (StructKeyExists(variables.eventLog, arguments.channel)) {
				local.out = [];
				local.seen = false;
				for (local.evt in variables.eventLog[arguments.channel]) {
					if (local.seen) {
						ArrayAppend(local.out, local.evt);
					}
					if (local.evt.id == arguments.lastEventId) {
						local.seen = true;
					}
				}
				// Return a copy, not the live retained array, so callers
				// cannot corrupt the event log by mutating the result.
				local.rv = local.seen ? local.out : Duplicate(variables.eventLog[arguments.channel]);
			}
		}
		return local.rv;
	}

}
