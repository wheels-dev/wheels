---
title: boolean()
description: "Adds one or more boolean columns to a table definition in a migration. Use this for columns that store true/false values."
sidebar:
  label: boolean()
  order: 0
---

## Signature

`boolean()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds one or more boolean columns to a table definition in a migration. Use this for columns that store true/false values.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>1. Add a single boolean column
boolean(columnNames="isActive");

2. Add multiple boolean columns
boolean(columnNames="isPublished, isVerified");

3. Add a boolean column with a default value
boolean(columnNames="isAdmin", default="false");

4. Add a boolean column that allows NULLs
boolean(columnNames="isArchived", allowNull=true);</code></pre>
