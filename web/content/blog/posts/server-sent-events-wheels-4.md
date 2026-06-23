---
title: 'Real-Time Without WebSockets: Server-Sent Events in Wheels 4.0'
slug: server-sent-events-wheels-4
publishedAt: '2026-06-23T14:00:00.000Z'
updatedAt: '2026-06-19T14:45:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - sse
  - real-time
  - controllers
categories: []
excerpt: >-
  A worked guide to Wheels 4.0's Server-Sent Events helpers — renderSSE for
  one-shot events, the initSSEStream/sendSSEEvent/closeSSEStream trio for
  long-lived streams, plus isSSERequest content negotiation, keep-alive
  heartbeats, and the engine-fragility sharp edges to test for.
coverImage: null
---

A user opens your dashboard and leaves the tab open. Somewhere in the background a worker finishes a report, an order ships, a teammate leaves a comment. The page sits there, stale, until the user gets bored and hits refresh — and when they do, half the time nothing's changed and they've burned a round-trip to find that out.

The reflex answer is "add WebSockets." But WebSockets are a bidirectional protocol, and what you actually have is a one-directional problem: the server has news, the client wants to hear it. You don't need the client talking back over the same channel. You need a pipe that pushes. Reaching for WebSockets here is bringing a phone call to a problem that wants a text message — now you're running a separate connection upgrade, a frame protocol, a heartbeat scheme, and probably a second process to hold all those sockets, all to deliver updates that only ever flow one way.

Server-Sent Events are the text message. One long-lived HTTP response, `Content-Type: text/event-stream`, the server writes `data: ...` lines, the browser's built-in `EventSource` parses them and fires events. Auto-reconnect is in the spec. Last-event tracking is in the spec. It rides ordinary HTTP, so your existing proxy, auth, and routing all just work.

Wheels 4.0 ships SSE as first-class controller helpers. This post walks both shapes — the one-shot event and the true stream — through a worked notifications feature, and then it's honest about the sharp edges, because one of them is genuinely engine-fragile and you need to know which one before you ship it.

## Two shapes, one decision

There are exactly two ways to send SSE in Wheels, and picking between them is the only real architecture decision you'll make:

| | `renderSSE()` | `initSSEStream()` + friends |
|---|---|---|
| Events per request | **One**, then the request ends | **Many**, over a held-open connection |
| Pipeline | Flows through `renderText()` — after-filters still run | **Bypasses** layouts *and* after-filters |
| Holds a worker thread | No — returns immediately | **Yes** — for the whole connection lifetime |
| How the client gets the next event | `EventSource` reconnects | Same connection keeps delivering |
| Spec-covered across engines | Yes | **No** — hand-test per engine (see Sharp edges) |

The mental model: `renderSSE()` is polling dressed up in SSE clothing. It sends one event and the request is done; the browser's `EventSource` reconnects on its own to pull the next one. It's simple, it's safe, it's covered by the test suite, and for most "is there anything new?" features it's all you want. The streaming trio is for when you genuinely need the server to push a burst of events down one connection without the reconnect tax — and it comes with strings attached.

Start with the simple one.

## One event per request: `renderSSE()`

Here's a notifications endpoint. A controller at `app/controllers/Notifications.cfc`, one action:

```cfm
// app/controllers/Notifications.cfc
component extends="Controller" {

    // GET /notifications/updates  ->  one SSE event per request
    function updates() {
        var unsent = model("Notification").findAll(
            where = "userId = #params.userId# AND sent = 0",
            order = "createdAt ASC"
        );

        // `data` is a REQUIRED string -> you serialize it yourself.
        // `event` is the SSE event-TYPE name the client listens for.
        // `retry` (ms) tells the browser how long to wait before reconnecting.
        renderSSE(
            data  = SerializeJSON(unsent),
            event = "notifications",
            retry = 5000
        );
    }
}
```

Three things to notice, because all three trip people up.

**You stringify the payload yourself.** `data` is `required string`. There is no auto-JSON in `renderSSE` — `model("Notification").findAll()` returns a query object, and handing a query straight to `data` throws a cast error. Call `SerializeJSON()` and pass the string. This is deliberate: SSE data can be anything (JSON, plain text, a CSV row), so the framework doesn't presume.

**The argument is `event`, not `eventName`.** It's the SSE *event-type* name — the string your client's `addEventListener` matches on. Not `type`, not `name`, not `eventName`. Get this wrong and you'll pass it as a positional arg by accident, which is its own problem (see below).

**`retry` is real but undocumented.** The CLAUDE.md SSE summary doesn't mention it, but `renderSSE` accepts `retry` (milliseconds) and emits a `retry:` line that tells the browser how long to wait before reconnecting. For a one-shot endpoint this is your polling interval — `retry=5000` means "come back in 5 seconds." That's the whole pacing mechanism for the `renderSSE` model.

Under the hood, `renderSSE` sets four headers — `Content-Type: text/event-stream`, `Cache-Control: no-cache`, `Connection: keep-alive`, and `X-Accel-Buffering: no` (the last one tells nginx not to buffer the stream) — formats the event, and hands the result to `renderText()`. That last detail matters: because it routes through the normal rendering pipeline, **your after-filters still run.** If you log responses or inject a header in an after-filter, that still happens for `renderSSE`. (It does *not* for the streaming trio — hold that thought.)

Never mix positional and named arguments — that's the number-one error source in Wheels code framework-wide, and SSE is no exception. The moment you pass any optional arg, go all-named:

```cfm
// WRONG — positional + named mixed
renderSSE(SerializeJSON(unsent), event="notifications");

// RIGHT — all named
renderSSE(data=SerializeJSON(unsent), event="notifications");
```

### Wiring the route

`config/routes.cfm` — nothing exotic, it's a normal GET:

```cfm
mapper()
    .get(name="notificationUpdates", to="notifications##updates")
    .resources("notifications")
    .root(to="home##index", method="get")
    .wildcard()
.end();
```

### The client side

This is the payoff for using a protocol the browser already knows. No library, no framework:

```javascript
// EventSource reconnects automatically after each single-event response,
// honoring the `retry` hint and sending Last-Event-ID on reconnect.
const es = new EventSource('/notifications/updates');

// Listen for the named event type you passed as `event=` in renderSSE.
es.addEventListener('notifications', (e) => {
  const payload = JSON.parse(e.data);
  console.log('new notifications:', payload);
});

es.onerror = (err) => console.warn('SSE connection error', err);
```

That's the entire client. `EventSource` opens the connection, your action sends one `notifications` event, the request ends, and `EventSource` reconnects on its own — waiting `retry` milliseconds — to pull the next batch. You never wrote a reconnect loop, a backoff, or a heartbeat. The browser owns all of that.

## Serving SSE and HTML from one action: `isSSERequest()`

Often the same URL should serve a live stream to `EventSource` clients and a plain HTML page to someone who navigates there in a browser tab. `isSSERequest()` checks the `Accept` header — `EventSource` always sends `Accept: text/event-stream` — and lets you branch:

```cfm
function index() {
    var items = model("Notification").findAll(order="createdAt DESC");

    if (isSSERequest()) {           // true when Accept: text/event-stream
        renderSSE(data=SerializeJSON(items), event="notifications");
        return;
    }

    // Falls through to the normal HTML view for browser navigations.
    notifications = items;
}
```

`isSSERequest()` takes no arguments and reads the header defensively — if `GetHTTPRequestData()` fails for any reason it treats the request as non-SSE rather than throwing. One URL, two representations, zero duplication. And in the HTML branch, remember to `cfparam` the view variable at the top of `views/notifications/index.cfm`:

```cfm
<cfparam name="notifications" default="">
```

Then loop it as a query, because finders return query objects, not arrays:

```cfm
<cfloop query="notifications">
    <li>#notifications.title# — #notifications.createdAt#</li>
</cfloop>
```

## When one event isn't enough: the streaming trio

`renderSSE` reconnects per event. That's fine until reconnection overhead matters — a high-frequency feed, a progress stream for a long-running job, a live activity ticker. For those you want one connection that stays open and delivers a burst of events. That's the `initSSEStream()` / `sendSSEEvent()` / `closeSSEStream()` trio.

The shape is different. `initSSEStream()` doesn't go through Wheels' rendering pipeline at all. It reaches for the underlying response object via the engine adapter, sets the same four SSE headers directly, calls `renderNothing()` so Wheels emits no body of its own, and **returns you the raw output writer.** You then write events to that writer yourself and close it when you're done.

Here's a bounded streaming endpoint. It mirrors the real streaming loop Wheels uses internally for its Channels feature — and "mirrors the real one" is doing a lot of work, because a naive streaming loop in CFML will eat a worker thread alive:

```cfm
// app/controllers/Feed.cfc
component extends="Controller" {

    // GET /feed/stream  ->  long-lived SSE stream
    // NOTE: bypasses layouts AND after-filters.
    function stream() {
        var writer = initSSEStream();   // takes NO args; returns the raw writer
        var timeoutSeconds   = 30;
        var heartbeatSeconds = 10;
        var lastId           = 0;

        try {
            var startTime     = GetTickCount() / 1000;
            var lastHeartbeat = startTime;

            while (true) {
                var now = GetTickCount() / 1000;
                if (now - startTime > timeoutSeconds) break;   // ALWAYS bound the loop

                var fresh = model("Notification").findAll(
                    where = "id > #lastId#",
                    order = "id ASC"
                );
                for (var n in fresh) {
                    sendSSEEvent(
                        writer = writer,
                        data   = SerializeJSON(n),
                        event  = "notification",
                        id     = n.id            // becomes Last-Event-ID on the client
                    );
                    lastId = n.id;
                    lastHeartbeat = now;
                }

                // Keep-alive comment so idle connections aren't dropped by proxies.
                if (now - lastHeartbeat > heartbeatSeconds) {
                    sendSSEComment(writer = writer);   // default comment 'ping'
                    lastHeartbeat = now;
                }

                if (writer.checkError()) break;   // client disconnected
                sleep(500);
            }
        } finally {
            closeSSEStream(writer);   // flush + close; swallows disconnect errors
        }
    }
}
```

Walk the load-bearing parts:

**`initSSEStream()` takes no arguments and returns the writer.** Capture it. Every subsequent call needs it.

**`sendSSEEvent(writer=..., data=..., ...)` pushes one event and flushes immediately.** It formats the event and calls `writer.write()` then `writer.flush()`, so the event hits the wire right away rather than sitting in a buffer. `writer` and `data` are both required; `event`, `id`, and `retry` carry the same meaning as in `renderSSE`. The `id` here is worth using — it becomes the client's `Last-Event-ID`, which is what lets a reconnecting client tell you where it left off.

**`sendSSEComment(writer=...)` is the heartbeat.** This one isn't in the CLAUDE.md summary at all, but it's the canonical keep-alive primitive — the same one the Channels loops use. It writes an SSE comment line (`: ping\n\n`), which the `EventSource` client ignores entirely but which keeps the connection from looking idle to a proxy that would otherwise drop it. It strips CR/LF from the comment so it can't be used to smuggle a fake field, defaults to `"ping"`, and flushes immediately.

**The loop is bounded three ways, and all three are mandatory.** CFML's request/response model means this loop holds a worker thread for the entire connection lifetime. An unbounded `while(true)` is a thread leak that will starve your pool. So: (1) a wall-clock `timeoutSeconds` cap that breaks the loop; (2) `writer.checkError()` to detect that the client disconnected; and (3) `sleep(500)` between polls so you're not spinning the CPU. The whole thing lives in a `try`/`finally` that calls `closeSSEStream(writer)` no matter how the loop exits.

**`closeSSEStream(writer)` is forgiving by design.** It flushes and closes inside a try/catch that swallows errors, because by the time you close, the client may already be gone — and a disconnected client is the normal way these streams end, not an exception worth surfacing. Both `closeSSEStream(writer)` and `closeSSEStream(writer=writer)` are valid; there's a single required argument.

## What goes on the wire

Both paths run your event through the same internal formatter, and it's worth seeing what it produces because the format explains a couple of the gotchas below. Fields come out in a fixed order — `id`, then `event`, then `retry`, then `data` — each emitted only when present (`retry` only when greater than zero), and the event terminates with a blank line:

```
id: 42
event: notification
retry: 5000
data: {"id":42,"title":"Order shipped"}

```

Multi-line data is split so each line gets its own `data:` prefix, which is exactly what the SSE spec wants — the browser reassembles them with `\n`. So this `data` value:

```cfml
sendSSEEvent(writer=writer, data="line one#Chr(10)#line two", event="log");
```

…goes out as two `data:` lines:

```
event: log
data: line one
data: line two

```

…and `e.data` on the client comes back as `"line one\nline two"`. That's correct behavior, not a bug — and it's also your field-injection defense, which brings us to the sharp edges.

## Sharp edges

SSE in Wheels is small and clean, but there are five things that will bite you if you don't know them up front. Every one of these is real and grounded in the implementation.

### 1. `initSSEStream()` is engine-fragile on BoxLang — hand-test it

This is the big one. `initSSEStream()` works by asking the engine adapter for the underlying response object and then calling `setContentType()`, `setHeader()`, and `getWriter()` on it. On Lucee and Adobe that object is the real `HttpServletResponse` (Lucee via `GetPageContext().getResponse()`, Adobe via `GetPageContext().getFusionContext().getResponse()`). **On BoxLang it isn't** — BoxLang's adapter deliberately returns the `PageContext` itself, with an explicit note that anything needing the real response object has to override `getResponse()` locally. So the streaming path is not guaranteed to resolve those methods the same way across engines.

Concretely: `renderSSE`, `isSSERequest`, and the internal formatter are all covered by the test suite and behave identically everywhere. The streaming trio — `initSSEStream` / `sendSSEEvent` / `closeSSEStream` end-to-end — is **not** exercised by the spec. If you're building a streaming endpoint, hand-test it on every engine you deploy to before you rely on it. The one-shot `renderSSE` model has no such caveat; if you want SSE that "just works" everywhere with zero hand-testing, that's the one to reach for.

### 2. `renderSSE` sends ONE event — it is not a stream

`renderSSE` is a single event and then the request ends, full stop. There is no loop inside it. If you want multiple events pushed down one connection you *must* use the streaming trio with your own loop. The reconnection between `renderSSE` events is handled entirely by the browser's `EventSource`. Don't try to call `renderSSE` in a loop — only the last call would matter, and you'd be confused for an afternoon.

### 3. After-filters run for `renderSSE` but are SKIPPED for streaming

Because `renderSSE` routes through `renderText()`, your after-filters run normally. Because `initSSEStream()` bypasses the entire rendering pipeline, after-filters (and layouts) **do not run** for streaming endpoints. If you have an after-filter doing response logging, audit-trail writes, or header injection, it silently won't fire on your streaming routes. Either move that logic into the action itself or accept that streaming endpoints are off the filter path.

### 4. You stringify the payload — always

`data` is `required string` on every one of these methods. There is no auto-JSON anywhere. Pass `SerializeJSON(yourData)`. Handing a struct, a query, or an array directly throws a cast error. This is consistent across `renderSSE`, `sendSSEEvent`, and the internal formatter — there's no path where the framework serializes for you.

### 5. Field injection is handled — you can't smuggle fake events through user data

If you're putting user-supplied content into `data`, you might worry that a malicious payload containing `\nevent: something\n` could inject a fake SSE field. It can't. The formatter strips CR/LF from `id` and `event` values outright, and for `data` it normalizes all line endings to LF and re-prefixes every line with `data: ` — so an embedded newline in user data just becomes another `data:` line that the client reassembles with `\n`, never a new field. That's the *correct* SSE behavior and the security property at the same time. You still want to validate and escape on the client when you render the payload into the DOM, but the SSE framing itself is safe.

One more thing worth knowing: all of these methods — including the `$`-prefixed internal formatter — are mixed onto every controller via `$integrateComponents("wheels.controller")`, which is why even the internal `$formatSSEEvent` is declared `public` (private mixin functions don't get integrated in Wheels). The practical takeaway is small but real: the six SSE helpers (`renderSSE`, `initSSEStream`, `sendSSEEvent`, `sendSSEComment`, `closeSSEStream`, `isSSERequest`) live in the protected-method surface, so don't name one of your own controller actions after them or the dispatcher will 404 the action instead of running it. Your own action names like `updates` and `stream` are fine — they aren't framework helpers.

## Which one should you use?

If you can express your feature as "the client asks, the server answers once, repeat" — and most notification, badge-count, and is-it-done-yet features can — use `renderSSE`. It's spec-covered, engine-safe, holds no thread, and the browser does your reconnect logic for free. Set `retry` to your polling cadence and you're done.

Reach for the streaming trio only when reconnection overhead is a real cost — high-frequency feeds, live progress on a long job, a ticker that updates several times a second. When you do, copy the bounded-loop pattern above verbatim: timeout cap, `checkError()` disconnect detection, heartbeat comments, `sleep` between polls, `try`/`finally` close. And hand-test it on every engine, because the streaming path is the one corner of Wheels SSE that the test suite doesn't have your back on.

Real-time doesn't have to mean a second protocol and a second process. For one-directional server-to-client updates — which is most of what "real-time" actually means in a web app — SSE over plain HTTP is the right-sized tool, and Wheels 4.0 makes it about four lines of controller code.
