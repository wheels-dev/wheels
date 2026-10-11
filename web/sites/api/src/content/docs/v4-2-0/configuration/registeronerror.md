---
title: registerOnError()
description: "Registers a callback function to be invoked when an unhandled error occurs."
sidebar:
  label: registerOnError()
  order: 0
---

## Signature

`registerOnError()` — returns `void`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Error Handling

## Description

Registers a callback function to be invoked when an unhandled error occurs.
Callbacks receive a single argument: the exception struct.
Multiple callbacks are invoked in registration order. A failing callback
is logged and skipped — it will not prevent other callbacks from running.
Should be called during app initialization, not per-request.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `callback` | `function` | yes | — | A function that accepts an exception struct argument. Must complete quickly — long-running callbacks delay error responses. |

</div>

## Examples

<pre><code class='javascript'>// 1. Register a simple error-notification callback in config/settings.cfm
registerOnError(function(exception) {
    writeLog(
        file = &quot;app-errors&quot;,
        type = &quot;error&quot;,
        text = &quot;Unhandled error: #exception.message# | Type: #exception.type#&quot;
    );
});

// 2. Register multiple callbacks — they fire in registration order
registerOnError(function(exception) {
    // Notify an external monitoring service
    local.payload = serializeJSON({
        message = exception.message,
        type    = exception.type,
        detail  = exception.detail
    });
    // cfhttp call to monitoring endpoint would go here
});

registerOnError(function(exception) {
    // Store the last error in the application scope for the admin dashboard
    application.lastError = {
        message   = exception.message,
        type      = exception.type,
        timestamp = now()
    };
});

// 3. Guard against slow operations — callbacks must complete quickly
registerOnError(function(exception) {
    // Do NOT perform long-running tasks here (database queries, large file I/O).
    // A failing callback is caught, logged, and skipped so other callbacks still run.
    if (structKeyExists(exception, &quot;message&quot;) &amp;&amp; len(exception.message)) {
        writeLog(file = &quot;wheels&quot;, type = &quot;error&quot;, text = &quot;App error: #exception.message#&quot;);
    }
});
</code></pre>
