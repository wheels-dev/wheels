---
title: char()
description: "Adds one or more CHAR columns to a table definition in a migration. Use this function to define fixed-length string columns when creating or modifying a table."
sidebar:
  label: char()
  order: 0
---

## Signature

`char()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds one or more CHAR columns to a table definition in a migration. Use this function to define fixed-length string columns when creating or modifying a table.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `limit` | `any` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>1. Add a single CHAR column
t.char(columnNames="status", limit=1, default="A", allowNull=false);

2. Add multiple CHAR columns
t.char(columnNames="type,code", limit=2, default="", allowNull=true);

3. Add a CHAR column without a limit
t.char(columnNames="initials", allowNull=true);</code></pre>
