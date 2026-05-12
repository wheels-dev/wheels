/**
 * Tests for Channel pub/sub system.
 * Tests the Channel.cfc core engine, global publish() function,
 * and controller mixin availability.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("Channel.cfc Core Engine", function() {

			beforeEach(function() {
				engine = new wheels.Channel();
			});

			it("can be instantiated", function() {
				expect(engine).toBeInstanceOf("wheels.Channel");
			});

			it("subscribe returns a subscriber ID", function() {
				var id = engine.subscribe(
					channel = "test.channel",
					callback = function(event) {}
				);
				expect(id).toBeString();
				expect(Len(id)).toBeGT(0);
			});

			it("subscribe uses provided ID when given", function() {
				var id = engine.subscribe(
					channel = "test.channel",
					callback = function(event) {},
					id = "my-custom-id"
				);
				expect(id).toBe("my-custom-id");
			});

			it("publish delivers events to subscribers", function() {
				var received = {event: ""};
				engine.subscribe(
					channel = "test.channel",
					callback = function(event) {
						received.event = event;
					}
				);

				engine.publish(
					channel = "test.channel",
					event = "notification",
					data = '{"msg":"hello"}'
				);

				expect(received.event).toBeStruct();
				expect(received.event.channel).toBe("test.channel");
				expect(received.event.event).toBe("notification");
				expect(received.event.data).toBe('{"msg":"hello"}');
			});

			it("publish returns result struct with subscriber count", function() {
				engine.subscribe(channel = "test.channel", callback = function(e) {});
				engine.subscribe(channel = "test.channel", callback = function(e) {});

				var result = engine.publish(
					channel = "test.channel",
					event = "update",
					data = "test"
				);

				expect(result).toBeStruct();
				expect(result).toHaveKey("id");
				expect(result).toHaveKey("channel");
				expect(result).toHaveKey("event");
				expect(result).toHaveKey("subscriberCount");
				expect(result).toHaveKey("timestamp");
				expect(result.subscriberCount).toBe(2);
			});

			it("publish to non-existent channel returns zero subscribers", function() {
				var result = engine.publish(
					channel = "no.such.channel",
					event = "test",
					data = "data"
				);
				expect(result.subscriberCount).toBe(0);
			});

			it("publish uses provided event ID when given", function() {
				var result = engine.publish(
					channel = "test.channel",
					event = "test",
					data = "data",
					id = "evt-42"
				);
				expect(result.id).toBe("evt-42");
			});

			it("unsubscribe removes a subscriber", function() {
				var id = engine.subscribe(
					channel = "test.channel",
					callback = function(e) {}
				);

				expect(engine.subscriberCount("test.channel")).toBe(1);

				var removed = engine.unsubscribe("test.channel", id);
				expect(removed).toBeTrue();
				expect(engine.subscriberCount("test.channel")).toBe(0);
			});

			it("unsubscribe returns false for non-existent subscriber", function() {
				var removed = engine.unsubscribe("test.channel", "nonexistent");
				expect(removed).toBeFalse();
			});

			it("unsubscribe returns false for non-existent channel", function() {
				var removed = engine.unsubscribe("no.such.channel", "some-id");
				expect(removed).toBeFalse();
			});

			it("error in one subscriber does not affect others", function() {
				var results = {count: 0};

				engine.subscribe(
					channel = "test.channel",
					callback = function(event) {
						throw(type = "TestError", message = "Deliberate error");
					}
				);

				engine.subscribe(
					channel = "test.channel",
					callback = function(event) {
						results.count++;
					}
				);

				engine.publish(channel = "test.channel", event = "test", data = "data");

				expect(results.count).toBe(1);
			});

			it("subscriberCount returns correct count", function() {
				expect(engine.subscriberCount("test.channel")).toBe(0);

				engine.subscribe(channel = "test.channel", callback = function(e) {});
				expect(engine.subscriberCount("test.channel")).toBe(1);

				engine.subscribe(channel = "test.channel", callback = function(e) {});
				expect(engine.subscriberCount("test.channel")).toBe(2);
			});

			it("subscriberCount returns 0 for non-existent channel", function() {
				expect(engine.subscriberCount("no.such.channel")).toBe(0);
			});

			it("getChannels returns list of active channels", function() {
				engine.subscribe(channel = "alpha", callback = function(e) {});
				engine.subscribe(channel = "beta", callback = function(e) {});
				engine.subscribe(channel = "gamma", callback = function(e) {});

				var channels = engine.getChannels();
				expect(channels).toBeArray();
				expect(ArrayLen(channels)).toBe(3);
				expect(channels).toInclude("alpha");
				expect(channels).toInclude("beta");
				expect(channels).toInclude("gamma");
			});

			it("getChannels returns empty array when no channels exist", function() {
				var channels = engine.getChannels();
				expect(channels).toBeArray();
				expect(ArrayLen(channels)).toBe(0);
			});

			it("removeChannel removes channel and all subscribers", function() {
				engine.subscribe(channel = "test.channel", callback = function(e) {});
				engine.subscribe(channel = "test.channel", callback = function(e) {});

				expect(engine.subscriberCount("test.channel")).toBe(2);

				engine.removeChannel("test.channel");

				expect(engine.subscriberCount("test.channel")).toBe(0);
				expect(engine.getChannels()).notToInclude("test.channel");
			});

			it("multiple channels are independent", function() {
				var resultA = {count: 0};
				var resultB = {count: 0};

				engine.subscribe(channel = "channel.a", callback = function(e) { resultA.count++; });
				engine.subscribe(channel = "channel.b", callback = function(e) { resultB.count++; });

				engine.publish(channel = "channel.a", event = "test", data = "data");

				expect(resultA.count).toBe(1);
				expect(resultB.count).toBe(0);
			});
		});

		describe("Global publish() Function", function() {

			beforeEach(function() {
				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);
			});

			it("$getChannelEngine returns a Channel instance for memory adapter", function() {
				var engine = _controller.$getChannelEngine("memory");
				expect(engine).toBeInstanceOf("wheels.Channel");
			});

			it("$getChannelEngine returns a DatabaseAdapter for database adapter", function() {
				var engine = _controller.$getChannelEngine("database");
				expect(engine).toBeInstanceOf("wheels.channel.DatabaseAdapter");
			});

			it("$getChannelEngine defaults to memory adapter", function() {
				var engine = _controller.$getChannelEngine();
				expect(engine).toBeInstanceOf("wheels.Channel");
			});
		});

		describe("Controller Mixin Availability", function() {

			beforeEach(function() {
				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);
			});

			it("subscribeToChannel method is available on controllers", function() {
				expect(_controller).toHaveKey("subscribeToChannel");
			});

			it("channelSSETag method is available on controllers", function() {
				expect(_controller).toHaveKey("channelSSETag");
			});
		});
	}
}
