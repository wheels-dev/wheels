---
title: api()
description: "Scope routes under an API path prefix. Shorthand for <code>.group(path=\"api\", name=\"api\", ...)</code>. Typically used in combination with <code>version()</code>"
sidebar:
  label: api()
  order: 0
---

## Signature

`api()` — returns `struct`

**Available in:** `mapper`
**Category:** Routing

## Description

Scope routes under an API path prefix. Shorthand for <code>.group(path="api", name="api", ...)</code>. Typically used in combination with <code>version()</code> to organize versioned API endpoints.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `path` | `string` | no | `api` | URL path prefix for the API. Defaults to `"api"`. |
| `name` | `string` | no | `api` | Name prefix for route names. Defaults to `"api"`. |
| `constraints` | `struct` | no | — | Variable patterns to apply to all child routes. |
| `callback` | `any` | no | — | A callback function to define nested routes within this API scope. |

</div>

