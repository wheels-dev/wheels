---
title: subscribeToChannel()
description: "Subscribe to a channel and stream events to the client via SSE."
sidebar:
  label: subscribeToChannel()
  order: 0
---

## Signature

`subscribeToChannel()` — returns `void`

**Available in:** `controller`


## Description

Subscribe to a channel and stream events to the client via SSE.
Opens a long-lived SSE connection that delivers matching events
until the client disconnects or the timeout is reached.
For the "memory" adapter, subscribes to the in-memory Channel
engine and buffers events for delivery. For the "database" adapter,
polls the wheels_events table at regular intervals.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `channel` | `string` | yes | — | The channel name to subscribe to (e.g. "user.42"). |
| `events` | `string` | no | — | Comma-delimited list of event types to filter. Empty = all events. |
| `lastEventId` | `string` | no | — | Resume from this event ID. Auto-detected from Last-Event-ID header if empty. |
| `adapter` | `string` | no | — | "memory" (default) or "database". |
| `pollInterval` | `numeric` | no | `2` | Seconds between polls for database adapter (default 2). |
| `timeout` | `numeric` | no | `300` | Maximum connection duration in seconds (default 300 = 5 minutes). |
| `heartbeatInterval` | `numeric` | no | `15` | Seconds between keep-alive pings (default 15). |

</div>

