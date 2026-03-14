# Channels — Pub/Sub for SSE

Channels add a pub/sub abstraction on top of Wheels' existing Server-Sent Events (SSE) support. The existing low-level SSE API (`renderSSE`, `initSSEStream`, `sendSSEEvent`) continues to work unchanged — channels are a higher-level layer built on top.

## Quick Start

```cfm
// Controller — subscribe the client to a channel via SSE
function notifications() {
    subscribeToChannel(
        channel = "user.#params.userId#",
        events = "notification,alert"
    );
}

// Publish from anywhere — model callback, job, controller, etc.
publish(
    channel = "user.42",
    event = "notification",
    data = SerializeJSON({title: "New message", body: "Hello!"})
);
```

```html
<!-- View — auto-generate EventSource script tag -->
#channelSSETag(channel="user.#params.userId#", route="notifications")#
```

## Configuration

```cfm
// config/settings.cfm

// Default adapter: "memory" (single server) or "database" (multi-server)
set(channelAdapter = "memory");
```

## Adapters

### Memory (Default)

In-memory pub/sub using `ConcurrentHashMap`. Events are delivered instantly to subscribers on the same server. No persistence — events are lost if no subscribers are connected.

Best for: single-server deployments, development.

### Database

Persists events to a `wheels_events` table (auto-created on first use). Subscribers poll the table at configurable intervals. Events are retained for 60 minutes by default with automatic cleanup.

Best for: multi-server deployments, event history/replay.

```cfm
// Use database adapter globally
set(channelAdapter = "database");

// Or per-call
subscribeToChannel(channel = "updates", adapter = "database");
publish(channel = "updates", event = "change", data = "...", adapter = "database");
```

## API Reference

### Global Functions

#### `publish(channel, event, data, adapter)`

Publish an event to a channel. Available anywhere global helpers are accessible (controllers, models, jobs, views).

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `channel` | string | required | Channel name (e.g. `"user.42"`, `"orders"`) |
| `event` | string | required | Event type (e.g. `"notification"`, `"update"`) |
| `data` | string | required | Event data (typically JSON) |
| `adapter` | string | `""` | `"memory"` or `"database"` (defaults to `channelAdapter` setting) |

Returns struct: `{id, channel, event, subscriberCount, timestamp}` (memory) or `{id, channel, event, persisted}` (database).

### Controller Functions

#### `subscribeToChannel(channel, events, lastEventId, adapter, pollInterval, timeout, heartbeatInterval)`

Open a long-lived SSE connection that streams events from a channel to the client. Automatically detects `Last-Event-ID` from request headers for resume support.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `channel` | string | required | Channel to subscribe to |
| `events` | string | `""` | Comma-delimited event types to filter (empty = all) |
| `lastEventId` | string | `""` | Resume from this event ID (auto-detected from header) |
| `adapter` | string | `""` | Override adapter type |
| `pollInterval` | numeric | `2` | Seconds between polls (database adapter only) |
| `timeout` | numeric | `300` | Max connection duration in seconds |
| `heartbeatInterval` | numeric | `15` | Seconds between keep-alive pings |

#### `channelSSETag(channel, route, controller, action, events)`

Generate a `<script>` tag with an EventSource connection to a channel endpoint.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `channel` | string | required | Channel name |
| `route` | string | `""` | Named route for the SSE endpoint |
| `controller` | string | `""` | Controller name (used if no route) |
| `action` | string | `"stream"` | Action name |
| `events` | string | `""` | Comma-delimited event types |

### Channel Engine (wheels.Channel)

The in-memory pub/sub engine. Usually accessed indirectly via `publish()` and `subscribeToChannel()`, but available directly for advanced use.

```cfm
var engine = $getChannelEngine("memory");

// Direct subscribe/publish
var subId = engine.subscribe(channel = "chat.room.1", callback = function(event) {
    // event = {id, channel, event, data, timestamp}
});

engine.publish(channel = "chat.room.1", event = "message", data = '{"text":"hi"}');

engine.unsubscribe("chat.room.1", subId);

// Inspect
engine.subscriberCount("chat.room.1");  // numeric
engine.getChannels();                    // array of channel names
engine.removeChannel("chat.room.1");     // remove channel + all subscribers
```

### DatabaseAdapter (wheels.channel.DatabaseAdapter)

Database-backed adapter. Usually accessed indirectly, but available for direct use.

```cfm
var adapter = $getChannelEngine("database");

adapter.publish(channel = "orders", event = "created", data = SerializeJSON(order));

// Poll for events since a timestamp or event ID
var events = adapter.poll(channel = "orders", since = DateAdd("n", -5, Now()));
var events = adapter.poll(channel = "orders", lastEventId = "evt-123");

// Manual cleanup (automatic cleanup runs every 5 minutes)
adapter.cleanup(olderThanMinutes = 30);
```

#### Database Table: `wheels_events`

Auto-created on first use. Schema:

| Column | Type | Description |
|--------|------|-------------|
| `id` | VARCHAR(36) PK | Event UUID |
| `channel` | VARCHAR(255) | Channel name |
| `event` | VARCHAR(255) | Event type |
| `data` | TEXT/CLOB | Event payload |
| `createdAt` | TIMESTAMP/DATETIME | When the event was published |

Indexes: `(channel, createdAt)`, `(createdAt)`.

## JavaScript Client

Include `wheels-sse.js` (located at `/wheels/assets/js/wheels-sse.js`) for a zero-dependency EventSource client with auto-reconnect.

```html
<script src="/wheels/assets/js/wheels-sse.js"></script>
<script>
// Basic usage
const sse = new WheelsSSE('/notifications/stream', {
    channel: 'user.42',
    events: ['notification', 'alert'],
    onMessage: (data, event, id) => {
        console.log('Received:', event, data);
    }
});

// Typed event listeners
sse.on('notification', (data, id) => {
    showNotification(data.title, data.body);
});

// Close when done
sse.close();

// Static factory
const sse2 = WheelsSSE.subscribe('/stream', {channel: 'orders'});
```

### Constructor Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `channel` | string | `""` | Channel name (added as URL param) |
| `events` | string[] | `[]` | Event types to filter |
| `lastEventId` | string | `""` | Resume from this event ID |
| `reconnectInterval` | number | `1000` | Initial reconnect delay (ms) |
| `maxReconnectInterval` | number | `30000` | Max reconnect delay (ms) |
| `reconnectDecay` | number | `2` | Backoff multiplier |
| `maxRetries` | number | `0` | Max reconnect attempts (0 = unlimited) |
| `onOpen` | Function | `null` | Called when connection opens |
| `onError` | Function | `null` | Called on connection error |
| `onMessage` | Function | `null` | Called for every event: `(data, event, id)` |

### Methods

- `on(event, callback)` — Add typed event listener. Returns `this` for chaining.
- `off(event, callback)` — Remove listener. Returns `this`.
- `close()` — Disconnect and stop reconnecting.
- `lastEventId` (getter) — Last received event ID.

### Auto-Reconnect

The client reconnects automatically with exponential backoff:
- Start at `reconnectInterval` (default 1s)
- Multiply by `reconnectDecay` (default 2x) each attempt
- Cap at `maxReconnectInterval` (default 30s)
- Stop after `maxRetries` (default 0 = unlimited)
- Reset backoff on successful connection

## Usage Patterns

### Per-User Notifications

```cfm
// Route
.get(name = "userNotifications", pattern = "notifications/stream", to = "notifications##stream")

// Controller
function stream() {
    subscribeToChannel(channel = "user.#session.userId#");
}

// Anywhere — model callback, job, etc.
publish(
    channel = "user.#user.id#",
    event = "notification",
    data = SerializeJSON({title: "Order shipped", orderId: order.id})
);
```

### Chat Room

```cfm
// Controller
function messages() {
    subscribeToChannel(
        channel = "chat.room.#params.roomId#",
        events = "message,typing,presence"
    );
}

function send() {
    // Save message to database...
    publish(
        channel = "chat.room.#params.roomId#",
        event = "message",
        data = SerializeJSON({user: session.userName, text: params.text})
    );
    renderNothing();
}
```

### Dashboard Updates (Database Adapter)

```cfm
// config/settings.cfm
set(channelAdapter = "database");

// Controller
function dashboard() {
    subscribeToChannel(
        channel = "dashboard.metrics",
        pollInterval = 5,
        timeout = 600
    );
}

// Background job publishes metrics
publish(
    channel = "dashboard.metrics",
    event = "metrics",
    data = SerializeJSON(calculateMetrics())
);
```
