---
title: primaryKey()
description: "Adds a primary key definition to the table. this method also allows for multiple primary keys."
sidebar:
  label: primaryKey()
  order: 0
---

## Signature

`primaryKey()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds a primary key definition to the table. this method also allows for multiple primary keys.
Accepts <code>columnName</code> / <code>columnNames</code> as aliases for <code>name</code> (per #2803) so the
PK helper matches the argument-naming convention every other column helper
in this file uses. The legacy <code>name</code> parameter keeps working — it is still
what the body reads and what <code>init()</code> passes when adding the conventional
<code>id</code> primary key.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | — | Legacy parameter for the primary-key column name. New code should prefer `columnName`. |
| `columnName` | `string` | no | — | Modern singular alias for `name` (matches sibling column helpers). |
| `columnNames` | `string` | no | — | Modern plural alias for `name`. Accepted for muscle-memory parity with `t.integer(columnNames=...)` etc. NOTE: unlike sibling helpers, this does NOT accept a comma-separated list — `primaryKey()` always creates one PK column, so `columnNames="a,b"` produces a single column literally named `a,b` (not two PKs). For composite PKs call `t.primaryKey()` multiple times. |
| `type` | `string` | no | `integer` |  |
| `autoIncrement` | `boolean` | no | `false` |  |
| `limit` | `numeric` | no | — |  |
| `precision` | `numeric` | no | — |  |
| `scale` | `numeric` | no | — |  |
| `references` | `string` | no | — |  |
| `referenceColumn` | `string` | no | `id` |  |
| `onUpdate` | `string` | no | — |  |
| `onDelete` | `string` | no | — |  |

</div>

