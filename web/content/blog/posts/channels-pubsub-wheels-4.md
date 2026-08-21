---
title: 'Channels: Pub/Sub for Wheels 4, No Extra Infrastructure'
slug: channels-pubsub-wheels-4
publishedAt: '2026-07-20T14:00:00.000Z'
updatedAt: '2026-07-06T05:23:50.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - channels
  - sse
  - realtime
categories: []
excerpt: >-
  SSE gives you the pipe; channels answer the harder question — how the model
  callback that knows something happened reaches the connection three requests
  away. publish(), subscribeToChannel(), channelSSETag(), the
  memory-vs-database adapter decision, and the named-event gotcha that catches
  almost everyone.
coverImage: null
---

Our [SSE post](https://blog.wheels.dev/posts/server-sent-events-wheels-4) covered the transport: `renderSSE()` and the streaming writers push events down an open HTTP connection. What it didn't cover is the question that shows up ten minutes after you ship your first stream: *how does the part of my app that knows something happened reach the part holding the connection?* The order was created in a model callback; the open EventSource lives in a controller action three requests away.

That's what channels are: an application-wide pub/sub layer on top of SSE. Publish from anywhere — a model callback, a background job, another request entirely — and every subscribed connection gets the event. Wheels 4 ships the whole stack: an engine, a controller mixin, a view helper, and a JavaScript client. Here's the tour, including the multi-server story and the one view-helper gotcha that catches almost everyone.

## The whole feature in four snippets

A subscribe action holding the connection:

```cfm
// app/controllers/Notifications.cfc
component extends="Controller" {
    function stream() {
        // Derive the channel server-side — don't trust a client-supplied channel name
        subscribeToChannel(channel = "user.#session.userId#");
    }
}
```

A route to it:

```cfm
.get(name = "notificationStream", pattern = "notifications/stream", to = "notifications##stream")
```

A publish from anywhere — here, a model callback:

```cfm
// app/models/Order.cfc
component extends="Model" {
    function config() {
        afterCreate("notifyUser");
    }

    private function notifyUser() {
        publish(
            channel = "user.#this.userId#",
            event = "message",
            data = SerializeJSON({title: "Order received", orderId: this.id})
        );
    }
}
```

And a view tag that opens the browser's EventSource:

```cfm
#channelSSETag(channel="user.#session.userId#", route="notificationStream")#
```

The generated script relays incoming events as `wheels:sse` CustomEvents on `document` — one listener handles everything:

```javascript
document.addEventListener('wheels:sse', (e) => {
    const payload = JSON.parse(e.detail.data);
    showToast(payload.title);
});
```

That's a working notification system. `publish()` is available everywhere global helpers are — controllers, models, jobs, views — and returns a struct telling you what happened (with the default adapter, including `subscriberCount`: how many open connections received it).

Note the deliberate move in the subscribe action: `channelSSETag()` passes its `channel` argument along as a URL parameter, and the action *ignores it*, deriving the channel from the session instead. Channel names are authorization boundaries — `user.42` should not be subscribable by user 43 with a URL edit. Derive server-side, or validate explicitly before honoring `params.channel`.

## Two adapters, one decision

`set(channelAdapter = "memory")` or `"database"` — and the difference is the architecture of your deployment, not a tuning knob.

**Memory** (the default) is in-process pub/sub on a `ConcurrentHashMap`. Delivery is synchronous and instant; empty channels are pruned automatically when the last subscriber disconnects, so per-entity names like `user.42` don't accumulate. Two hard limits, both by design: no persistence (an event published while nobody's connected is simply gone — no replay, so `Last-Event-ID` can't recover a missed window), and single-server only. Perfect for development and one-box deployments; wrong the day you add a second app server, because a publish on server A never reaches a subscriber on server B.

**Database** persists every event to a `wheels_events` table (auto-created on first use, no migration) and subscribers poll it — every 2 seconds by default. That buys you the two things memory can't do: events cross servers, and events *persist*, so a reconnecting browser's `Last-Event-ID` resume actually recovers what it missed. The trade is latency bounded by the poll interval instead of instant.

Retention is 60 minutes by default, swept opportunistically on the publish path — bounded passes (at most 1,000 expired rows at a time, at most every 5 minutes) so no single `publish()` blocks on a giant `DELETE`. On busy multi-server setups, add a real sweep from a scheduled task; `cleanup()` on the database adapter takes `olderThanMinutes` and `maxRows` and returns the rows deleted.

The honest positioning, straight from the design: this is SSE + polling, not WebSockets. One-directional server-push with automatic browser reconnection covers notifications, dashboards, progress bars, and activity feeds — most of what teams reach for WebSockets to do — with zero extra infrastructure. If you need bidirectional or sub-poll-interval latency across servers, you want an actual socket server, and Wheels won't pretend otherwise.

## The subscription lifecycle knobs

`subscribeToChannel()` holds the connection open until the client disconnects or `timeout` elapses (default 300 seconds) — and that's fine, because when it ends, the browser's EventSource reconnects automatically and the next request resumes; the helper reads the `Last-Event-ID` header on its own. Heartbeat comments go out every 15 seconds by default so proxies don't kill an "idle" connection. You can filter delivery with `events="orderShipped,orderCancelled"`, override the adapter per call, and tune `pollInterval` for the database adapter.

(Running SSE behind nginx? The same buffering rules from the SSE post apply — `proxy_buffering off` on the streaming location.)

## The gotcha: named events and `channelSSETag()`

Here's the one that generates support questions. The script `channelSSETag()` emits wires only the browser's default `onmessage` handler — which fires **only for events whose type is `message`**. Publish with `event="notification"` and the event arrives at the browser as a *named* SSE event… which the generated script silently ignores. Your publish succeeded, `subscriberCount` said 1, the network tab shows the frame, and your listener never fires.

Two ways to be right:

- Publishing with `event="message"` (as the example above does) whenever `channelSSETag()` is your client — put the semantic type inside your JSON payload instead.
- Or skip the helper and use named events properly: the shipped `WheelsSSE` JavaScript client — a zero-dependency EventSource wrapper with typed listeners, `Last-Event-ID` tracking, and exponential-backoff reconnection — or a plain `EventSource` with `addEventListener('notification', ...)`.

## Where channels earn their keep

The pattern that makes this feature click is *decoupling the knower from the holder*: the model callback that knows an order shipped publishes one line and moves on; the controller holding a connection — possibly on another server, with the database adapter — delivers it. Background jobs publishing progress (`jobs.#jobId#`), admin dashboards on an `orders` firehose channel, per-user notification streams: all the same four snippets with different channel names.

The full reference — including the `WheelsSSE` client API and the database table schema — is the [Channels guide](https://guides.wheels.dev/v4-0-0/digging-deeper/channels/); the transport underneath it is covered in [Server-Sent Events](https://guides.wheels.dev/v4-0-0/digging-deeper/server-sent-events/).

