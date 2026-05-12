---
title: verifies()
description: "Instructs Wheels to verify that some specific criteria are met before running an action."
sidebar:
  label: verifies()
  order: 0
---

## Signature

`verifies()` — returns `void`

**Available in:** `controller`
**Category:** Configuration Functions

## Description

Instructs Wheels to verify that some specific criteria are met before running an action.
Note that all undeclared arguments will be passed to <code>redirectTo()</code> call if a <code>handler</code> is not specified.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `only` | `string` | no | — | List of action names to limit this verification to. |
| `except` | `string` | no | — | List of action names to exclude this verification from. |
| `post` | `any` | no | — | Set to true to verify that this is a `POST` request. |
| `get` | `any` | no | — | Set to true to verify that this is a `GET` request. |
| `ajax` | `any` | no | — | Set to true to verify that this is an `AJAX` request. |
| `cookie` | `string` | no | — | Verify that the passed in variable name exists in the cookie scope. |
| `session` | `string` | no | — | Verify that the passed in variable name exists in the session scope. |
| `params` | `string` | no | — | Verify that the passed in variable name exists in the params struct. |
| `handler` | `string` | no | — | Pass in the name of a function that should handle failed verifications. The default is to just abort the request when a verification fails. |
| `cookieTypes` | `string` | no | — | List of types to check each listed cookie value against (will be passed through to your CFML engine's `IsValid` function). |
| `sessionTypes` | `string` | no | — | List of types to check each list session value against (will be passed through to your CFML engine's `IsValid` function). |
| `paramsTypes` | `string` | no | — | List of types to check each params value against (will be passed through to your CFML engine's `IsValid` function). |

</div>

