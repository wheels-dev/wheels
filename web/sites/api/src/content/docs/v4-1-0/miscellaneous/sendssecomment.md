---
title: sendSSEComment()
description: "Send an SSE comment (keep-alive ping) through a streaming writer."
sidebar:
  label: sendSSEComment()
  order: 0
---

## Signature

`sendSSEComment()` — returns `void`

**Available in:** `controller`


## Description

Send an SSE comment (keep-alive ping) through a streaming writer.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `writer` | `any` | yes | — | The writer object returned by initSSEStream(). |
| `comment` | `string` | no | `ping` | Optional comment text. |

</div>

