---
title: flashMessages()
description: "Displays a marked-up listing of messages that exist in the Flash."
sidebar:
  label: flashMessages()
  order: 0
---

## Signature

`flashMessages()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Displays a marked-up listing of messages that exist in the Flash.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `keys` | `string` | no | — | The key (or list of keys) to show the value for. You can also use the `key` argument instead for better readability when accessing a single key. |
| `class` | `string` | no | `flash-messages` | HTML `class` to set on the `div` element that contains the messages. |
| `includeEmptyContainer` | `boolean` | no | `false` | Includes the `div` container even if the Flash is empty. |
| `encode` | `boolean` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

