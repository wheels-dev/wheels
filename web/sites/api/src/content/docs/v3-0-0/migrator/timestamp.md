---
title: timestamp()
description: "Used to add one or more <code>TIMESTAMP</code> (or <code>DATETIME</code>) columns to a table definition. It lets you specify default values, whether the column"
sidebar:
  label: timestamp()
  order: 0
---

## Signature

`timestamp()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Used to add one or more <code>TIMESTAMP</code> (or <code>DATETIME</code>) columns to a table definition. It lets you specify default values, whether the column allows NULL, and even override the underlying SQL type through the columnType argument. This is especially useful when you need to track creation and update times or work with custom timestamp fields. Only available in a migrator CFC.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |
| `columnType` | `string` | no | `datetime` |  |

</div>

## Examples

<pre><code class='javascript'>1. Add a basic timestamp column
t.timestamp(&quot;createdAt&quot;)

2. Add multiple timestamp columns
t.timestamp(&quot;createdAt, updatedAt&quot;)

3. Add a timestamp column with a default value
t.timestamp(columnNames=&quot;createdAt&quot;, default=&quot;CURRENT_TIMESTAMP&quot;)

4. Add a nullable timestamp column
t.timestamp(columnNames=&quot;deletedAt&quot;, allowNull=true)

5. Override column type to use TIMESTAMP instead of DATETIME
t.timestamp(columnNames=&quot;syncedAt&quot;, columnType=&quot;timestamp&quot;)
</code></pre>
