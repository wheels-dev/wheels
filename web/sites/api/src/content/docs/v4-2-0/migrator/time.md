---
title: time()
description: "adds time columns to table definition"
sidebar:
  label: time()
  order: 0
---

## Signature

`time()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

adds time columns to table definition



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `any` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a single time column to a new table
t = createTable(name='schedules');
	t.string(columnNames='title', limit=255, allowNull=false);
	t.time(columnNames='startTime', allowNull=false);
	t.timestamps();
t.create();

// 2. Add multiple time columns at once
t = createTable(name='shifts');
	t.string(columnNames='employeeName', limit=100, allowNull=false);
	t.time(columnNames='clockIn,clockOut', allowNull=false);
	t.timestamps();
t.create();

// 3. Add a nullable time column with a default to an existing table
t = changeTable(name='stores');
	t.time(columnNames='openTime', allowNull=true, default='09:00:00');
t.change();
</code></pre>
