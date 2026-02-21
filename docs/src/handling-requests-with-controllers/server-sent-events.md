---
description: >-
  Push real-time updates from your Wheels application to the browser using
  the Server-Sent Events standard.
---

# Server-Sent Events (SSE)

Server-Sent Events (SSE) is a standard that allows a server to push updates to a web browser over a single HTTP connection. Unlike WebSockets, SSE is one-directional (server to client), uses standard HTTP, and automatically reconnects if the connection drops.

Wheels provides built-in controller helpers for SSE responses, making it simple to add real-time features like notifications, live feeds, and progress updates.

## When to Use SSE

SSE is ideal for:

* **Notifications**: Alert users about new messages, comments, or system events
* **Live feeds**: Stream activity logs, stock prices, or social media updates
* **Progress tracking**: Show real-time progress for long-running operations
* **Dashboard updates**: Push metric changes without polling

For bidirectional communication (e.g., chat), consider WebSockets instead.

## Single Event Response

The simplest approach is `renderSSE()`, which sends a single SSE-formatted event and closes the connection. The client's `EventSource` will automatically reconnect and receive the next update.

```javascript
function notifications() {
    var data = model("Notification").findAll(
        where="userId=#params.userId# AND sent=0"
    );
    renderSSE(
        data=SerializeJSON(data),
        event="notifications",
        id=CreateUUID()
    );
}
```

### renderSSE() Parameters

| Parameter | Type   | Default | Description |
|-----------|--------|---------|-------------|
| `data`    | string | (required) | The event data to send (typically JSON) |
| `event`   | string | `""` | Optional event type name |
| `id`      | string | `""` | Optional event ID for reconnection tracking |
| `retry`   | numeric | `0` | Reconnection interval in milliseconds (0 = browser default) |

## Streaming Multiple Events

For long-lived connections that send multiple events, use the streaming API:

```javascript
function stream() {
    // Initialize the SSE stream (sets headers, gets writer)
    var writer = initSSEStream();

    // Send multiple events
    var items = model("Activity").findAll(where="new=1", order="createdAt");
    for (var item in items) {
        sendSSEEvent(
            writer=writer,
            data=SerializeJSON({
                id: item.id,
                type: item.activityType,
                message: item.description
            }),
            event="activity",
            id=item.id
        );
    }

    // Close the stream when done
    closeSSEStream(writer=writer);
}
```

### Streaming Helper Functions

| Function | Description |
|----------|-------------|
| `initSSEStream()` | Sets SSE headers and returns a writer object |
| `sendSSEEvent(writer, data, event, id, retry)` | Sends a single event through the writer |
| `sendSSEComment(writer, comment)` | Sends a comment (keep-alive ping) |
| `closeSSEStream(writer)` | Flushes and closes the stream |

## Content Negotiation

Use `isSSERequest()` to detect whether the request comes from an `EventSource` client and respond accordingly:

```javascript
function updates() {
    var latestData = model("Update").findAll(order="createdAt DESC", maxRows=10);

    if (isSSERequest()) {
        renderSSE(data=SerializeJSON(latestData), event="updates");
    } else {
        updates = latestData;
        renderView();
    }
}
```

This allows the same action to serve both a regular HTML page and SSE updates.

## Client-Side Usage

Use the browser's built-in `EventSource` API to connect:

```javascript
// Connect to the SSE endpoint
const eventSource = new EventSource('/controller/notifications');

// Listen for named events
eventSource.addEventListener('notifications', function(e) {
    const data = JSON.parse(e.data);
    console.log('New notifications:', data);
    updateNotificationBadge(data);
});

// Listen for generic messages (events without a name)
eventSource.onmessage = function(e) {
    console.log('Message:', e.data);
};

// Handle connection errors
eventSource.onerror = function(e) {
    console.error('SSE connection error');
    // EventSource automatically reconnects
};

// Close the connection when done
// eventSource.close();
```

### Passing the Last Event ID

When an `EventSource` reconnects after a dropped connection, it sends the last received event ID in the `Last-Event-ID` header. You can use this to resume from where the client left off:

```javascript
function notifications() {
    var lastId = GetHttpRequestData().headers["Last-Event-ID"] ?: "";

    if (Len(lastId)) {
        var data = model("Notification").findAll(
            where="userId=#params.userId# AND id > '#lastId#'"
        );
    } else {
        var data = model("Notification").findAll(
            where="userId=#params.userId# AND sent=0"
        );
    }

    renderSSE(data=SerializeJSON(data), event="notifications", id=data.id);
}
```

## Routing

SSE endpoints are regular controller actions. Define routes as you would for any other action:

```javascript
mapper()
    .resources(name="notifications", only="index")
    .get(name="activityStream", to="activities##stream")
    .get(name="dashboardUpdates", to="dashboard##updates")
.end();
```

## Keep-Alive Pings

For long-lived streaming connections, send periodic comments to prevent proxy timeouts:

```javascript
function stream() {
    var writer = initSSEStream();

    // Send a keep-alive comment
    sendSSEComment(writer=writer, comment="ping");

    // Send actual data
    sendSSEEvent(writer=writer, data=SerializeJSON(getData()), event="update");

    closeSSEStream(writer=writer);
}
```

SSE comments (lines starting with `:`) are ignored by the client but keep the connection alive through proxies and load balancers.

## Best Practices

1. **Use JSON for data**: Always `SerializeJSON()` your data for structured payloads
2. **Name your events**: Use the `event` parameter so clients can listen for specific event types
3. **Include event IDs**: Set the `id` parameter to enable automatic reconnection resumption
4. **Set appropriate retry intervals**: Use the `retry` parameter to control reconnection timing
5. **Keep payloads small**: SSE is best for lightweight notifications, not large data transfers
6. **Use content negotiation**: Check `isSSERequest()` to serve both HTML and SSE from the same action
7. **Consider connection limits**: Browsers limit the number of concurrent SSE connections per domain (typically 6). Use a single multiplexed stream when possible
