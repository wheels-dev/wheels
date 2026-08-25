/**
 * Channel hardener desks S1–S10. Desk IDs are locked. Do not renumber.
 *
 * Directory-scoped so `wheels test --core --ci --filter=channel` discovers it.
 *
 * FLIP: S1 publish throw, S4 unknown adapter throw, S5 memory lastEventId
 * replay, S7 named-event addEventListener, S8 empty channel name throw.
 * PROVE: S2 cleanup catch-any → 0, S3 $ensureEventsTable SELECT swallow,
 * S6 Last-Event-ID header swallow.
 * FIX: S9 drain must not drop mid-loop publishes. S10 tightens assertions.
 */
component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("S1 publish throws instead of persisted:false", function() {

			beforeEach(function() {
				adapter = new wheels.channel.DatabaseAdapter();
				adapter.poll(channel = "test.hard.s1", since = DateAdd("n", -1, Now()));
			});

			it("throws Wheels.Channel.PublishFailed on a duplicate event id", function() {
				var eventId = "s1-dup-#Replace(CreateUUID(), '-', '', 'all')#";
				var channelName = "test.hard.s1.#Replace(CreateUUID(), '-', '', 'all')#";
				adapter.publish(channel = channelName, event = "e", data = "first", id = eventId);

				var state = {threw = false, type = "", persisted = true};
				try {
					adapter.publish(channel = channelName, event = "e", data = "second", id = eventId);
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				}
				expect(state.threw).toBeTrue();
				expect(state.type).toBe("Wheels.Channel.PublishFailed");
				expect(state.persisted).toBeTrue();
			});

			it("does not return persisted:false from a failing INSERT", function() {
				var src = FileRead(ExpandPath("/wheels/channel/DatabaseAdapter.cfc"));
				var publishFn = Mid(src, FindNoCase("public struct function publish", src), 1600);
				expect(FindNoCase("persisted: false", publishFn)).toBe(
					0,
					"DatabaseAdapter.publish must not fail-open with persisted:false"
				);
			});

		});

		describe("S2 cleanup catch-any returns 0", function() {

			it("returns 0 when DELETE cannot run", function() {
				var broken = new wheels.tests._assets.channel.BrokenDatasourceAdapter();
				expect(broken.cleanup()).toBe(0);
				expect(broken.cleanup(maxRows = 10)).toBe(0);
			});

			it("does not throw when cleanup SQL fails", function() {
				var broken = new wheels.tests._assets.channel.BrokenDatasourceAdapter();
				var state = {threw = false};
				try {
					broken.cleanup(olderThanMinutes = 60);
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeFalse();
			});

			it("keeps the catch-any fail-open on cleanup()", function() {
				var src = FileRead(ExpandPath("/wheels/channel/DatabaseAdapter.cfc"));
				var cleanupFn = Mid(src, FindNoCase("public numeric function cleanup", src), 4500);
				expect(FindNoCase("catch (any e)", cleanupFn)).toBeGT(0);
				expect(FindNoCase("return 0;", cleanupFn)).toBeGT(0);
			});

		});

		describe("S3 $ensureEventsTable treats any SELECT error as missing table", function() {

			it("does not throw to the caller when the existence SELECT fails", function() {
				var broken = new wheels.tests._assets.channel.BrokenDatasourceAdapter(tableVerified = false);
				makePublic(broken, "$ensureEventsTable");
				var state = {threw = false, result = true};
				try {
					state.result = broken.$ensureEventsTable();
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeFalse();
				expect(state.result).toBeFalse();
			});

			it("falls through from the SELECT catch to CREATE TABLE", function() {
				var src = FileRead(ExpandPath("/wheels/channel/DatabaseAdapter.cfc"));
				var ensureFn = Mid(src, FindNoCase("private boolean function $ensureEventsTable", src), 2800);
				var selectCatch = FindNoCase("catch (any e)", ensureFn);
				var createTable = FindNoCase("CREATE TABLE wheels_events", ensureFn);
				expect(selectCatch).toBeGT(0);
				expect(createTable).toBeGT(selectCatch);
				var catchBody = Mid(ensureFn, selectCatch, createTable - selectCatch);
				expect(FindNoCase("return ", catchBody)).toBe(
					0,
					"$ensureEventsTable SELECT catch must fall through to CREATE, not return"
				);
				expect(FindNoCase("rethrow", catchBody)).toBe(0);
				expect(FindNoCase("throw(", catchBody)).toBe(0);
			});

		});

		describe("S4 unknown adapter throws", function() {

			beforeEach(function() {
				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);
			});

			it("throws Wheels.Channel.UnknownAdapter for redis", function() {
				var state = {threw = false, type = ""};
				try {
					_controller.$getChannelEngine("redis");
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				}
				expect(state.threw).toBeTrue();
				expect(state.type).toBe("Wheels.Channel.UnknownAdapter");
			});

			it("throws Wheels.Channel.UnknownAdapter for an empty-looking typo", function() {
				var state = {threw = false, type = ""};
				try {
					_controller.$getChannelEngine("memeory");
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				}
				expect(state.threw).toBeTrue();
				expect(state.type).toBe("Wheels.Channel.UnknownAdapter");
			});

			it("still returns Channel for memory and DatabaseAdapter for database", function() {
				expect(_controller.$getChannelEngine("memory")).toBeInstanceOf("wheels.Channel");
				expect(_controller.$getChannelEngine("database")).toBeInstanceOf("wheels.channel.DatabaseAdapter");
			});

		});

		describe("S5 memory lastEventId replay", function() {

			it("replays events published after lastEventId", function() {
				var engine = new wheels.Channel();
				var channelName = "test.hard.s5.#Replace(CreateUUID(), '-', '', 'all')#";
				engine.publish(channel = channelName, event = "e", data = "one", id = "s5-a");
				engine.publish(channel = channelName, event = "e", data = "two", id = "s5-b");
				engine.publish(channel = channelName, event = "e", data = "three", id = "s5-c");

				var replayed = engine.replay(channel = channelName, lastEventId = "s5-a");
				expect(ArrayLen(replayed)).toBe(2);
				expect(replayed[1].id).toBe("s5-b");
				expect(replayed[2].id).toBe("s5-c");
				expect(replayed[1].data).toBe("two");
			});

			it("returns an empty array when lastEventId is the newest event", function() {
				var engine = new wheels.Channel();
				var channelName = "test.hard.s5.#Replace(CreateUUID(), '-', '', 'all')#";
				engine.publish(channel = channelName, event = "e", data = "one", id = "s5-last");
				var replayed = engine.replay(channel = channelName, lastEventId = "s5-last");
				expect(ArrayLen(replayed)).toBe(0);
			});

			it("$subscribeMemory sends replayed events and not the lastEventId itself", function() {
				var stubDir = ExpandPath("/testbox/system/stubs");
				CreateObject("java", "java.io.File").init(stubDir).mkdirs();

				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);

				var engine = new wheels.Channel();
				var channelName = "test.hard.s5.sub.#Replace(CreateUUID(), '-', '', 'all')#";
				engine.publish(channel = channelName, event = "note", data = "old", id = "s5-old");
				engine.publish(channel = channelName, event = "note", data = "new", id = "s5-new");

				var fakeWriter = createStub();
				fakeWriter.$("checkError").$results(false, true);

				prepareMock(_controller);
				_controller.$(method = "initSSEStream", returns = fakeWriter);
				_controller.$(method = "$getChannelEngine", returns = engine);
				_controller.$(method = "sendSSEEvent");
				_controller.$(method = "sendSSEComment");
				_controller.$(method = "closeSSEStream");

				_controller.$subscribeMemory(
					channel = channelName,
					eventFilter = [],
					lastEventId = "s5-old",
					timeout = 30,
					heartbeatInterval = 60
				);

				var sent = _controller.$callLog().sendSSEEvent;
				expect(ArrayLen(sent)).toBe(1);
				expect(sent[1].id).toBe("s5-new");
				expect(sent[1].data).toBe("new");
			});

		});

		describe("S6 Last-Event-ID header swallow", function() {

			it("subscribeToChannel still reaches the memory loop when lastEventId is empty", function() {
				var stubDir = ExpandPath("/testbox/system/stubs");
				CreateObject("java", "java.io.File").init(stubDir).mkdirs();

				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);

				var fakeWriter = createStub();
				fakeWriter.$("checkError").$results(true);

				var engine = new wheels.Channel();
				prepareMock(_controller);
				_controller.$(method = "initSSEStream", returns = fakeWriter);
				_controller.$(method = "$getChannelEngine", returns = engine);
				_controller.$(method = "sendSSEEvent");
				_controller.$(method = "sendSSEComment");
				_controller.$(method = "closeSSEStream");

				var state = {threw = false};
				try {
					_controller.subscribeToChannel(channel = "test.hard.s6", lastEventId = "", timeout = 1);
				} catch (any e) {
					state.threw = true;
				}
				expect(state.threw).toBeFalse();
				expect(ArrayLen(_controller.$callLog().initSSEStream)).toBe(1);
			});

			it("keeps the GetHTTPRequestData catch-any around Last-Event-ID", function() {
				var src = FileRead(ExpandPath("/wheels/controller/channels.cfc"));
				var subscribeFn = Mid(src, FindNoCase("public void function subscribeToChannel", src), 2200);
				expect(FindNoCase("Last-Event-ID", subscribeFn)).toBeGT(0);
				expect(FindNoCase("catch (any e)", subscribeFn)).toBeGT(0);
				var headerCatch = Mid(
					subscribeFn,
					FindNoCase("GetHTTPRequestData", subscribeFn),
					400
				);
				expect(FindNoCase("catch (any e)", headerCatch)).toBeGT(0);
				expect(FindNoCase("rethrow", headerCatch)).toBe(0);
			});

		});

		describe("S7 channelSSETag named-event addEventListener", function() {

			beforeEach(function() {
				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);
			});

			it("registers addEventListener for each named event", function() {
				var html = _controller.channelSSETag(
					channel = "user.1",
					controller = "dummy",
					action = "dummy",
					events = "notification,alert"
				);
				expect(html).toInclude("addEventListener(");
				expect(html).toInclude("'notification'");
				expect(html).toInclude("'alert'");
				expect(FindNoCase("src.onmessage", html)).toBeGT(0);
			});

			it("does not emit addEventListener when events is empty", function() {
				var html = _controller.channelSSETag(
					channel = "user.1",
					controller = "dummy",
					action = "dummy"
				);
				expect(FindNoCase("addEventListener", html)).toBe(0);
				expect(FindNoCase("src.onmessage", html)).toBeGT(0);
			});

		});

		describe("S8 empty channel name throws", function() {

			it("Channel.publish rejects an empty name", function() {
				var engine = new wheels.Channel();
				var state = {threw = false, type = ""};
				try {
					engine.publish(channel = "", event = "e", data = "d");
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				}
				expect(state.threw).toBeTrue();
				expect(state.type).toBe("Wheels.Channel.InvalidName");
			});

			it("Channel.subscribe rejects a whitespace-only name", function() {
				var engine = new wheels.Channel();
				var state = {threw = false, type = ""};
				try {
					engine.subscribe(channel = "   ", callback = function(event) {});
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				}
				expect(state.threw).toBeTrue();
				expect(state.type).toBe("Wheels.Channel.InvalidName");
			});

			it("DatabaseAdapter.publish rejects an empty name", function() {
				var adapter = new wheels.channel.DatabaseAdapter();
				var state = {threw = false, type = ""};
				try {
					adapter.publish(channel = "", event = "e", data = "d");
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				}
				expect(state.threw).toBeTrue();
				expect(state.type).toBe("Wheels.Channel.InvalidName");
			});

			it("subscribeToChannel rejects an empty name before opening SSE", function() {
				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);
				var state = {threw = false, type = ""};
				try {
					_controller.subscribeToChannel(channel = "");
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				}
				expect(state.threw).toBeTrue();
				expect(state.type).toBe("Wheels.Channel.InvalidName");
			});

			it("channelSSETag rejects an empty name", function() {
				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);
				var state = {threw = false, type = ""};
				try {
					_controller.channelSSETag(channel = "", controller = "dummy", action = "dummy");
				} catch (any e) {
					state.threw = true;
					state.type = e.type;
				}
				expect(state.threw).toBeTrue();
				expect(state.type).toBe("Wheels.Channel.InvalidName");
			});

		});

		describe("S9 memory drain does not drop mid-loop events", function() {

			beforeEach(function() {
				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);
			});

			it("$drainChannelBuffer keeps an event published during the loop", function() {
				var buffer = new wheels.tests._assets.channel.MidLoopPublishBuffer();
				var drained = _controller.$drainChannelBuffer(buffer);
				expect(ArrayLen(drained)).toBe(3);
				expect(drained[1]).toBe("a");
				expect(drained[2]).toBe("b");
				expect(drained[3]).toBe("c");
				expect(buffer.wasCleared()).toBeFalse();
			});

			it("$subscribeMemory does not call clear() on the live buffer", function() {
				var src = FileRead(ExpandPath("/wheels/controller/channels.cfc"));
				var memFn = Mid(src, FindNoCase("public void function $subscribeMemory", src), 2800);
				expect(FindNoCase(".clear()", memFn)).toBe(
					0,
					"$subscribeMemory must not clear() the buffer or it drops mid-loop publishes"
				);
				expect(FindNoCase("$drainChannelBuffer", memFn)).toBeGT(0);
			});

		});

		describe("S10 tightened assertions", function() {

			beforeEach(function() {
				params = {controller = "dummy", action = "dummy"};
				_controller = g.controller("dummy", params);
			});

			it("mixin methods are functions, not just struct keys", function() {
				expect(_controller).toHaveKey("subscribeToChannel");
				expect(_controller).toHaveKey("channelSSETag");
				expect(IsCustomFunction(_controller.subscribeToChannel)).toBeTrue();
				expect(IsCustomFunction(_controller.channelSSETag)).toBeTrue();
			});

			it("channelSSETag emits an EventSource for the given channel", function() {
				var html = _controller.channelSSETag(
					channel = "user.s10",
					controller = "dummy",
					action = "dummy"
				);
				expect(Len(html)).toBeGT(0);
				expect(FindNoCase("EventSource", html)).toBeGT(0);
				expect(FindNoCase("channel=user.s10", html)).toBeGT(0);
			});

		});

	}

}
