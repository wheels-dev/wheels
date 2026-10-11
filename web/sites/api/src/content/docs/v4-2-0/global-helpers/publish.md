---
title: publish()
description: "Publish an event to a channel."
sidebar:
  label: publish()
  order: 0
---

## Signature

`publish()` — returns `struct`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Channel Functions

## Description

Publish an event to a channel.
Delegates to the in-memory Channel engine or the DatabaseAdapter
depending on the adapter argument (or the global channelAdapter setting).
Can be called from controllers, models, jobs, or anywhere with access
to global helpers.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `channel` | `string` | yes | — | The channel name to publish to (e.g. "user.42"). |
| `event` | `string` | yes | — | The event type (e.g. "notification", "update"). |
| `data` | `string` | yes | — | The event data as a string (typically JSON). |
| `adapter` | `string` | no | — | Adapter to use: "memory" (default) or "database". |

</div>

## Examples

<pre><code class='javascript'>// 1. Publish a notification event to a user-specific channel (in-memory adapter)
data = serializeJSON({message = &quot;Your order has shipped!&quot;, orderId = 42});
result = publish(channel=&quot;user.42&quot;, event=&quot;notification&quot;, data=data);
// result -&gt; {success: true, ...}

// 2. Publish an update event using the database adapter for persistence
data = serializeJSON({status = &quot;active&quot;, updatedAt = Now()});
result = publish(channel=&quot;products&quot;, event=&quot;update&quot;, data=data, adapter=&quot;database&quot;);

// 3. Broadcast a chat message to a room channel
result = publish(
    channel = &quot;chat.room.5&quot;,
    event   = &quot;message&quot;,
    data    = serializeJSON({user = &quot;alice&quot;, text = &quot;Hello everyone!&quot;})
);
</code></pre>
