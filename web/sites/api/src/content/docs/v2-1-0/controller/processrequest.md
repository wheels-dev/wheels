---
title: processRequest()
description: "Creates a controller and calls an action on it."
sidebar:
  label: processRequest()
  order: 0
---

## Signature

`processRequest()` — returns `any`

**Available in:** `controller`, `model`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Creates a controller and calls an action on it.
Which controller and action that's called is determined by the params passed in.
Returns the result of the request either as a string or in a struct with <code>body</code>, <code>emails</code>, <code>files</code>, <code>flash</code>, <code>redirect</code>, <code>status</code>, and <code>type</code>.
Primarily used for testing purposes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `params` | `struct` | yes | — | The params struct to use in the request (make sure that at least `controller` and `action` are set). |
| `method` | `string` | no | `get` | The HTTP method to use in the request (`get`, `post` etc). |
| `returnAs` | `string` | no | — | Pass in `struct` to return all information about the request instead of just the final output (`body`). |
| `rollback` | `string` | no | `false` | Pass in `true` to roll back all database transactions made during the request. |
| `includeFilters` | `string` | no | `true` | Set to `before` to only execute "before" filters, `after` to only execute "after" filters or `false` to skip all filters. |

</div>

