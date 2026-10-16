---
title: datetime()
description: "adds datetime columns to table definition"
sidebar:
  label: datetime()
  order: 0
---

## Signature

`datetime()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

adds datetime columns to table definition



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `any` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a single datetime column to a new table
t = createTable(name='orders');
	t.string(columnNames='status', limit=50, allowNull=false);
	t.datetime(columnNames='placedAt', allowNull=false);
	t.timestamps();
t.create();

// 2. Add multiple datetime columns at once
t = createTable(name='appointments');
	t.string(columnNames='title', limit=255, allowNull=false);
	t.datetime(columnNames='startAt,endAt', allowNull=false);
	t.timestamps();
t.create();

// 3. Add a nullable datetime column with a default to an existing table
t = changeTable(name='posts');
	t.datetime(columnNames='publishedAt', allowNull=true, default='NOW()');
t.change();
</code></pre>
