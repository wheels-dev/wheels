# Server-Sent Events (SSE)

## Description
Wheels provides built-in support for Server-Sent Events, enabling real-time server-to-client communication. SSE is ideal for live notifications, activity feeds, progress updates, and any scenario where the server needs to push data to the browser.

## Key Points
- `renderSSE()` sends a single SSE event as the controller response
- `initSSEStream()` / `sendSSEEvent()` / `closeSSEStream()` enable multi-event streaming
- `isSSERequest()` detects EventSource clients for content negotiation
- SSE headers (`Content-Type: text/event-stream`, `Cache-Control: no-cache`) are set automatically
- Works with the standard Wheels controller pipeline

## Single Event Response

The simplest pattern: respond to an EventSource request with one SSE event per request. The client automatically reconnects to get the next event.

```cfm
// Controller action
function notifications() {
    var data = model("Notification").findAll(
        where="userId=#params.userId# AND sent=0",
        order="createdAt DESC",
        maxRows=10
    );
    renderSSE(
        data=SerializeJSON(data),
        event="notifications",
        id=data.recordCount ? data.id[1] : ""
    );
}
```

### renderSSE() Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `data` | string | Yes | Event data (typically JSON). Multi-line strings are handled correctly. |
| `event` | string | No | Event type name. Client listens with `addEventListener(event, ...)`. |
| `id` | string | No | Event ID. Sent back as `Last-Event-ID` on reconnect. |
| `retry` | numeric | No | Reconnection interval in milliseconds. |

## Streaming Multiple Events

For sending multiple events over a single connection, use the streaming API. This bypasses the normal Wheels rendering pipeline and writes directly to the response output.

```cfm
function stream() {
    var writer = initSSEStream();

    // Send a series of events
    var items = model("Activity").findAll(where="createdAt > '#params.since#'", order="createdAt");
    for (var item in items) {
        sendSSEEvent(
            writer=writer,
            data=SerializeJSON({id: item.id, message: item.message, time: item.createdAt}),
            event="activity",
            id=item.id
        );
    }

    // Send a keep-alive comment
    sendSSEComment(writer=writer, comment="done");

    closeSSEStream(writer=writer);
}
```

### Streaming API

| Function | Description |
|----------|-------------|
| `initSSEStream()` | Sets SSE headers, gets the response writer. Returns a writer object. |
| `sendSSEEvent(writer, data, event, id, retry)` | Writes and flushes one SSE event to the stream. |
| `sendSSEComment(writer, comment)` | Writes a comment line (`:comment`). Useful for keep-alive pings. |
| `closeSSEStream(writer)` | Flushes and closes the connection. |

## Content Negotiation

Detect whether the current request comes from an EventSource client:

```cfm
function updates() {
    if (isSSERequest()) {
        var data = model("Update").findAll(where="new=1");
        renderSSE(data=SerializeJSON(data), event="updates");
    } else {
        // Normal HTML response
        updates = model("Update").findAll(order="createdAt DESC");
        renderView();
    }
}
```

## Client-Side Usage

### Basic EventSource
```javascript
const es = new EventSource('/controller/notifications?userId=42');

es.onmessage = function(event) {
    console.log('Message:', event.data);
};

es.addEventListener('notifications', function(event) {
    const data = JSON.parse(event.data);
    // Update the UI with notification data
});

es.onerror = function(event) {
    console.error('SSE connection error');
};
```

### With Last-Event-ID
```javascript
// The browser automatically sends Last-Event-ID on reconnect.
// Access it in your controller via:
// GetHTTPRequestData().headers["Last-Event-ID"]
```

## SSE Event Format

The SSE protocol uses a simple text format. Wheels handles formatting automatically:

```
id: 42
event: notification
retry: 5000
data: {"message":"New order received","orderId":123}

```

- Each field is on its own line (`field: value`)
- Multi-line data gets multiple `data:` lines
- Events are terminated by a blank line (`\n\n`)
- Comment lines start with `:` (used for keep-alive)

## Routing for SSE Endpoints

```cfm
mapper()
    .resources(name="notifications", only="index")
    .get(name="notificationStream", pattern="notifications/stream", to="notifications##stream")
    .wildcard()
.end();
```

## Best Practices

1. **Keep events small** — Send only the data the client needs
2. **Use event types** — Let clients subscribe to specific events with `addEventListener()`
3. **Include event IDs** — Enables automatic resume after disconnection
4. **Set reasonable retry intervals** — Default browser retry is ~3 seconds
5. **Use `renderSSE()` for simple cases** — Polling-based SSE is simpler and more reliable
6. **Use streaming for burst updates** — `initSSEStream()` is ideal for sending a batch of events
7. **Add keep-alive comments** — Prevents proxy timeouts on long-lived connections

## Related
- [Controller Rendering](./rendering.md)
- [API Controllers](./api.md)
- [CORS Requests](../../configuration/security.md)
