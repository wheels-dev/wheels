---
title: datetime()
description: "Adds datetime columns to a table definition when creating or altering a table in a migration. These columns store both date and time values."
sidebar:
  label: datetime()
  order: 0
---

## Signature

`datetime()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds datetime columns to a table definition when creating or altering a table in a migration. These columns store both date and time values.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>Example 1: Basic usage
t = createTable(name="appointments"); 
t.datetime(columnNames="startAt,endAt");
t.create();

Creates startAt and endAt columns as datetime columns in the appointments table.

---

Example 2: With NULL allowed
t = createTable(name="events"); 
t.datetime(columnNames="cancelledAt", allowNull=true);
t.create();

cancelledAt column allows NULL values.

---

Example 3: With default timestamp
t = createTable(name="logs"); 
t.datetime(columnNames="createdAt", default="CURRENT_TIMESTAMP");
t.create();

Sets createdAt to the current timestamp by default.

---

Example 4: Multiple datetime columns with defaults
t = createTable(name="tasks"); 
t.datetime(columnNames="assignedAt,completedAt", default="CURRENT_TIMESTAMP", allowNull=false);
t.create();

Both columns are non-nullable and default to the current timestamp.</code></pre>
