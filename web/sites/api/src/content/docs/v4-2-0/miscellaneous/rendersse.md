---
title: renderSSE()
description: "Render a single SSE event as the controller response."
sidebar:
  label: renderSSE()
  order: 0
---

## Signature

`renderSSE()` — returns `void`

**Available in:** `controller`


## Description

Render a single SSE event as the controller response.
This sets appropriate headers and formats the response as an SSE event.
The client should use EventSource to connect and will receive this single event.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `data` | `string` | yes | — | The event data to send (string). Will be sent as-is. |
| `event` | `string` | no | — | Optional event type name. Client can listen for specific event types. |
| `id` | `string` | no | — | Optional event ID. Client sends Last-Event-ID header on reconnect. |
| `retry` | `numeric` | no | `0` | Optional reconnection time in milliseconds. Tells client how long to wait before reconnecting. |

</div>

