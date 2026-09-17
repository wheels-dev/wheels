---
title: binary()
description: "Adds binary columns to table definition."
sidebar:
  label: binary()
  order: 0
---

## Signature

`binary()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds binary columns to table definition.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `any` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a single binary column to a new table
t = createTable(name='attachments');
	t.string(columnNames='filename', limit=255, allowNull=false);
	t.binary(columnNames='fileData');
	t.timestamps();
t.create();

// 2. Add multiple binary columns at once
t = createTable(name='media');
	t.string(columnNames='title', limit=255, allowNull=false);
	t.binary(columnNames='thumbnail,fullImage', allowNull=false);
	t.timestamps();
t.create();

// 3. Add a binary column with a default when altering an existing table
t = changeTable(name='documents');
	t.binary(columnNames='rawContent', allowNull=true);
t.change();
</code></pre>
