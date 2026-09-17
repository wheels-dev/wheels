---
title: date()
description: "Adds date columns to table definition."
sidebar:
  label: date()
  order: 0
---

## Signature

`date()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds date columns to table definition.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `any` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a single date column to a new table
t = createTable(name='events');
	t.string(columnNames='title', limit=255, allowNull=false);
	t.date(columnNames='eventDate', allowNull=false);
	t.timestamps();
t.create();

// 2. Add multiple date columns at once
t = createTable(name='subscriptions');
	t.string(columnNames='plan', limit=100, allowNull=false);
	t.date(columnNames='startDate,endDate', allowNull=false);
	t.timestamps();
t.create();

// 3. Add a date column with a default value to an existing table
t = changeTable(name='users');
	t.date(columnNames='birthDate', allowNull=true);
t.change();
</code></pre>
