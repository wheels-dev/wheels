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

