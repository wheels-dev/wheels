---
title: 'Request IDs, /up, and Logs a Machine Can Read: Observability in Wheels 4'
slug: observability-in-wheels-4
publishedAt: '2026-07-14T14:00:00.000Z'
updatedAt: '2026-07-06T05:06:04.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - observability
  - logging
  - middleware
  - deployment
categories: []
excerpt: >-
  Three small pieces of plumbing turn 'the site gave me an error around
  lunchtime' into a single grep: the RequestId middleware, the /up health
  endpoint your app already ships, and a forty-line JSON logging pattern. Plus
  the two health-endpoint mistakes everyone makes once.
coverImage: null
---

A customer emails: "the site gave me an error around lunchtime." You have nginx access logs, a Lucee application log, an error tracker, and — somewhere in all three — one request that matters. Nothing connects them. You grep by timestamp and hope lunchtime was quiet.

The fix is not a bigger monitoring bill. It's three small pieces of plumbing, all of which ship with Wheels 4: a request ID that stitches every log line about one request together, a health endpoint your load balancer and deployer already know how to poll, and log lines shaped so a machine can parse them. This post wires up all three, and is honest about which parts the framework deliberately leaves to your infrastructure.

## One UUID to bind them: `RequestId`

`wheels.middleware.RequestId` generates one UUID per request, stores it at `request.wheels.requestId`, and writes it to the `X-Request-Id` response header. That's the entire component — and it's the single highest-leverage line in your observability setup, because every other system can now reference the same key: the browser's network tab shows the header, your logs carry it, your error tracker tags it, and the customer's screenshot of the error page can include it.

It's not enabled by default. Add it to the global pipeline, **first**, so everything downstream can read it:

```cfm
// config/settings.cfm
set(middleware = [
    new wheels.middleware.RequestId(),
    new wheels.middleware.SecurityHeaders()
]);
```

If a reverse proxy in front of you already stamps `X-Request-Id` (nginx's `$request_id`, an ALB trace header), you can honor the inbound value instead — the [Observability guide](https://guides.wheels.dev/v4-0-0/deployment/observability-and-logging/#accept-a-client-supplied-request-id-optional) has a small wrapper middleware for that. Do it only for headers your own infrastructure sets: an ID accepted from an untrusted client is an injection vector into your logs.

## The health endpoint you already have

If your app came from `wheels new`, you already ship a liveness endpoint and may not know it: `app/controllers/Up.cfc`, routed at `/up`. It exists for two jobs:

1. **Deploy gating.** `wheels deploy`'s proxy probes `/up` before flipping traffic to a freshly deployed node — it's the default healthcheck path. Any load balancer can poll the same URL.
2. **Warm-up.** Returning 200 from `/up` forces the dispatch → controller → render path to compile on a new node, so the first real visitor gets warm latency instead of paying the one-time first-request compile that dominates CFML cold-start time. The scaffolded controller even suggests touching your hottest models (`model("Post").count()`) to warm ORM metadata before cutover.

Keep `/up` cheap, read-only, and unauthenticated — a probe that hits every two seconds must never open anything expensive.

Liveness ("the process serves requests") and readiness ("its dependencies work") are different questions, though. When you want the second one, add a readiness check that actually pings the database:

```cfm
// app/controllers/Health.cfc
component extends="Controller" {

    function config() {
        // Without provides(), renderWith() falls back to the HTML view
        // (which doesn't exist) and the endpoint 500s.
        provides("html,json");
    }

    function index() {
        local.checks = {
            "database": $checkDatabase(),
            "environment": get("environment")
        };
        local.healthy = local.checks.database.ok;

        // The argument is `status` — renderWith() has no `statusCode`
        // argument, and an unknown argument would be swallowed, returning
        // HTTP 200 to the load balancer even on the degraded path.
        renderWith(
            data = {
                "status": local.healthy ? "ok" : "degraded",
                "checks": local.checks,
                "requestId": request.wheels.requestId ?: ""
            },
            status = local.healthy ? 200 : 503
        );
    }

    private struct function $checkDatabase() {
        try {
            queryExecute("SELECT 1", {}, {datasource = get("dataSourceName")});
            return {ok: true};
        } catch (any e) {
            return {ok: false, error: e.message};
        }
    }
}
```

Point the load balancer's liveness probe at `/up`, the readiness probe at this, and resist the urge to check everything — a readiness endpoint that fails because a third-party analytics API is slow will cycle your nodes for no reason. Check what's load-bearing; nothing else.

Note the two comments in that sample. They're the two mistakes everyone makes on their first health endpoint: forgetting `provides()` (the JSON render falls back to a nonexistent HTML view and your *health check* 500s, which is a special kind of embarrassing) and typing `statusCode=` instead of `status=` (silently swallowed, so the degraded path reports 200 and your load balancer cheerfully routes traffic to a node that can't reach its database).

## Logs a machine can read

Wheels doesn't ship a logging facade, and that's a considered position: every CFML engine has `writeLog()`, the framework uses it directly, and a facade would be one more API between you and your log files. What it *does* leave to you is shape — the default plain-text lines are fine for tailing and awkward for a collector to index.

The pattern: a thin component that emits one JSON object per line, stamps the request ID automatically, and registers as a singleton:

```cfm
// app/lib/Log.cfc
component output="false" {

    public void function info(required string message, struct context = {}) {
        $write(arguments.message, "information", arguments.context);
    }

    public void function warn(required string message, struct context = {}) {
        $write(arguments.message, "warning", arguments.context);
    }

    public void function error(required string message, struct context = {}) {
        $write(arguments.message, "error", arguments.context);
    }

    private void function $write(required string message, required string level, required struct context) {
        local.payload = {
            "ts": DateTimeFormat(Now(), "iso"),
            "level": arguments.level,
            "message": arguments.message,
            "requestId": request.wheels.requestId ?: "",
            // Bare get() isn't available in a plain component — it's a
            // framework mixin. Read the application scope directly.
            "environment": application.wheels.environment ?: ""
        };
        StructAppend(local.payload, arguments.context, true);

        writeLog(text = SerializeJSON(local.payload), type = arguments.level, file = "application");
    }
}
```

```cfm
// config/services.cfm
local.di.map("log").to("app.lib.Log").asSingleton();
```

```cfm
// any controller
function config() { inject("log"); }

function create() {
    order = model("Order").new(params.order);
    if (order.save()) {
        this.log.info("order.created", {orderId: order.id, total: order.total});
        redirectTo(route="order", key=order.id);
    } else {
        this.log.warn("order.create_failed", {errors: order.allErrors()});
        renderView(action="new");
    }
}
```

Every line on disk is now a self-describing JSON object with a timestamp, level, message, request ID, and environment. Log files land in the engine's log directory (Lucee: `{server}/logs/`, Adobe: `cfusion/logs/`), and shipping them to a collector is a sidecar's job — Vector, Fluent Bit, whatever your stack already runs. The framework writes files; the infrastructure reads them; neither needs to know the other's name.

Use dot-namespaced event names (`order.created`, `auth.login_failed`) rather than prose — six months from now, "count of `order.create_failed` by day" is a query, not a regex archaeology project.

## The signals Wheels writes without being asked

Two log surfaces come free and are worth knowing about before an incident, not during one:

- **`wheels_security.log`** — reload-password attempts (accepted and rejected, rate-limited per client IP), environment switches via URL, and a boot warning if `reloadPassword` is blank in production. If someone is guessing your reload password, this is where it shows.
- **The debug bar** (development only) tells you per-request timing, params, and the executed route — the same request anatomy you're wiring logs for in production, live on every dev page load. The [Debug Panel guide](https://guides.wheels.dev/v4-0-0/digging-deeper/debug-panel/) has the tour.

## What Wheels deliberately doesn't do

No bundled metrics library, no APM agent, no log shipper. A CFML app is a JVM process serving HTTP: every mature tool in that space — JMX exporters, FusionReactor, OpenTelemetry Java agents, your cloud's log collector — already works on it. The framework's contract is to make its own signals *legible* (request IDs, health endpoints, parseable lines) and stay out of the way of whatever you plug in on top. The full setup, including the log-shipping options, is in the [Observability and Logging guide](https://guides.wheels.dev/v4-0-0/deployment/observability-and-logging/).

The whole stack above is maybe forty lines of code you write once. The payoff is the difference between "the site gave me an error around lunchtime" and `grep 7f3a‑…` returning the request, its log lines, its timing, and its stack trace — in order, first try.

