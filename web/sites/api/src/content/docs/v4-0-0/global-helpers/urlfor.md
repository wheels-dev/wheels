---
title: URLFor()
description: "Creates an internal URL based on supplied arguments."
sidebar:
  label: URLFor()
  order: 0
---

## Signature

`URLFor()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Creates an internal URL based on supplied arguments.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `route` | `string` | no | — | Name of a route that you have configured in `config/routes.cfm`. |
| `controller` | `string` | no | — | Name of the controller to include in the URL. |
| `action` | `string` | no | — | Name of the action to include in the URL. |
| `key` | `any` | no | — | Key(s) to include in the URL. |
| `params` | `string` | no | — | Any additional parameters to be set in the query string (example: `wheels=cool&x=y`). Please note that Wheels uses the `&` and `=` characters to split the parameters and encode them properly for you. However, if you need to pass in `&` or `=` as part of the value, then you need to encode them (and only them), example: `a=cats%26dogs%3Dtrouble!&b=1`. |
| `anchor` | `string` | no | — | Sets an anchor name to be appended to the path. |
| `onlyPath` | `boolean` | no | `true` | If `true`, returns only the relative URL (no protocol, host name or port). |
| `host` | `string` | no | — | Set this to override the current host. |
| `protocol` | `string` | no | — | Set this to override the current protocol. |
| `port` | `numeric` | no | `0` | Set this to override the current port number. |
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |
| `$encodeForHtmlAttribute` | `boolean` | no | `false` |  |
| `$URLRewriting` | `string` | no | `[runtime expression]` |  |

</div>

