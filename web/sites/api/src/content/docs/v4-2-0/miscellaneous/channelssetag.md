---
title: channelSSETag()
description: "Generate a 'script' tag that creates an EventSource for a channel."
sidebar:
  label: channelSSETag()
  order: 0
---

## Signature

`channelSSETag()` — returns `string`

**Available in:** `controller`


## Description

Generate a 'script' tag that creates an EventSource for a channel.
Convenience view helper for quickly wiring up SSE in templates.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `channel` | `string` | yes | — | The channel name. |
| `route` | `string` | no | — | Named route for the SSE endpoint. |
| `controller` | `string` | no | — | Controller name (used with action if no route). |
| `action` | `string` | no | `stream` | Action name (default "stream"). |
| `events` | `string` | no | — | Comma-delimited list of event types. |

</div>

