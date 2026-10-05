# Server-Sent Events (SSE)

Part of the Wheels application guide; start with `../CLAUDE.md`.

```cfm
function notifications() {
    var data = model("Notification").where("userId", session.userId).get();
    renderSSE(data=SerializeJSON(data), event="notifications", id=params.lastId);
}

function stream() {
    var writer = initSSEStream();
    for (var item in items) sendSSEEvent(writer=writer, data=SerializeJSON(item), event="update");
    closeSSEStream(writer=writer);
}

if (isSSERequest()) { renderSSE(data="..."); }
```

Client: `const es = new EventSource('/controller/notifications');`

## Channels (publish / subscribe)

```cfm
// Publish from anywhere: a controller, a model callback, a job. data is a string (usually JSON).
publish(channel="user.#user.id#", event="notification", data=SerializeJSON({text: "Hi"}));

// Subscribe action: streams the channel and blocks this request until timeout (default 300s) or disconnect.
function stream() {
    subscribeToChannel(channel="user.#session.userId#", events="notification,alert", lastEventId=params.lastEventId ?: "");
}

// View: an EventSource for the action; each message is dispatched on document as a "wheels:sse" CustomEvent.
#channelSSETag(channel="user.#session.userId#", route="notificationStream")#
```

- `subscribeToChannel(channel, events, lastEventId, adapter, pollInterval=2, timeout=300, heartbeatInterval=15)`. `events` is an exact, case-sensitive list: write `"a,b"`, not `"a, b"`. There are no wildcard channels; one connection subscribes to one channel.
- Resume: it reads the `Last-Event-ID` header itself. The `wheels-sse` JS client sends `lastEventId` as a URL parameter instead, so pass `lastEventId=params.lastEventId ?: ""` as above.
- Adapters: `set(channelAdapter="memory")` (default) or `"database"`, or `adapter=` per call. Memory lives in one application instance (no cross-server delivery, lost on restart) and keeps the last 100 events per channel for resume. Database stores events in `wheels_events` (created on first use, no migration), works across servers, delivers within `pollInterval` seconds, and deletes events older than 60 minutes as you publish. A new database subscriber without a `lastEventId` first receives the last 5 minutes of events.
- Errors: an empty channel name throws `Wheels.Channel.InvalidName`; a failed database publish throws `Wheels.Channel.PublishFailed`; `channelSSETag()` without `route` or `controller` throws `Wheels.Channel.MissingEndpoint`.

### Authorising subscribers

Channels have no built-in access control: `subscribeToChannel()` accepts any non-empty name.

- `channelSSETag()` puts the channel name in the URL (`?channel=`), so `subscribeToChannel(channel=params.channel)` lets a client subscribe to any channel by editing the URL. Derive the channel on the server (`"user.#session.userId#"`), or check that the requested channel belongs to the user before subscribing.
- Filters and checks in the action run once, when the connection opens. Events are not re-checked as they stream, so a user whose access is revoked keeps receiving events until the connection ends (at most `timeout` seconds; the browser then reconnects and your filters run again). Use a shorter `timeout` for sensitive channels, and publish to a channel name the revoked user can't derive.
