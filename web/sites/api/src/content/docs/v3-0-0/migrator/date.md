---
title: date()
description: "date() is a table definition function used in a migration CFC to add one or more DATE columns to a table."
sidebar:
  label: date()
  order: 0
---

## Signature

`date()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

date() is a table definition function used in a migration CFC to add one or more DATE columns to a table.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>// In a migration CFC
t = createTable(name="events");
t.date(columnNames="startDate,endDate",  default="",  allowNull=false);
t.create();</code></pre>
