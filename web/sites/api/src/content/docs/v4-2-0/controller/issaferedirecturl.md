---
title: isSafeRedirectUrl()
description: "Returns <code>true</code> when <code>redirectUrl</code> stays on this site: a relative URL, or an absolute or"
sidebar:
  label: isSafeRedirectUrl()
  order: 0
---

## Signature

`isSafeRedirectUrl()` — returns `boolean`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Returns <code>true</code> when <code>redirectUrl</code> stays on this site: a relative URL, or an absolute or
protocol-relative URL whose host is the current server. This is the same rule
<code>redirectTo(url=...)</code> applies before it redirects, so use it to check a return-to URL
(for example <code>params.return_to</code>) before storing it or building a link from it.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `redirectUrl` | `string` | yes | — | The URL to check. |
| `serverName` | `string` | no | `[runtime expression]` | The host to compare against. Defaults to the current request's server name. |

</div>

