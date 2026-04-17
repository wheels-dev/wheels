---
title: text()
description: "Used within a migration to add one or more text columns to a database table definition. Text columns are designed for storing larger amounts of character data c"
sidebar:
  label: text()
  order: 0
---

## Signature

`text()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Used within a migration to add one or more text columns to a database table definition. Text columns are designed for storing larger amounts of character data compared to standard string or varchar columns. This function allows you to define the column name, set a default value, and control whether the column allows null values.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

## Examples

<pre><code class='javascript'>1. In a migration file
t.text(&quot;description&quot;);

2. Creates both summary and notes columns as text types
t.text(&quot;summary,notes&quot;);

3. Adds a column with a default placeholder text
t.text(columnNames=&quot;details&quot;, default=&quot;N/A&quot;);

4. Adds a text column that must always have a value
t.text(columnNames=&quot;bio&quot;, allowNull=false);

5. Adds a column with a default value and disallows nulls
t.text(columnNames=&quot;comments&quot;, default=&quot;No comments provided&quot;, allowNull=false);
</code></pre>
