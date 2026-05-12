---
title: sendSSEEvent()
description: "Send an SSE event through a streaming writer obtained from initSSEStream()."
sidebar:
  label: sendSSEEvent()
  order: 0
---

## Signature

`sendSSEEvent()` — returns `void`

**Available in:** `controller`


## Description

Send an SSE event through a streaming writer obtained from initSSEStream().

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `writer` | `any` | yes | — | The writer object returned by initSSEStream(). |
| `data` | `string` | yes | — | The event data to send. |
| `event` | `string` | no | — | Optional event type name. |
| `id` | `string` | no | — | Optional event ID. |
| `retry` | `numeric` | no | `0` | Optional reconnection time in milliseconds. |

</div>

