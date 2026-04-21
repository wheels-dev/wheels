---
title: change()
description: "Used in migrations to alter an existing table in the database. This function allows you to modify the structure of a table, such as adding, modifying, or removi"
sidebar:
  label: change()
  order: 0
---

## Signature

`change()` — returns `void`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Used in migrations to alter an existing table in the database. This function allows you to modify the structure of a table, such as adding, modifying, or removing columns.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `addColumns` | `boolean` | no | `false` |  |

</div>

## Examples

<pre><code class='javascript'>1. Alter a table to add new columns
t = changeTable(name='employees');
t.string(columnNames="fullName", default="", allowNull=true, limit="255");
t.change();

</code></pre>
