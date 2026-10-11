---
title: text()
description: "Adds text columns to table definition."
sidebar:
  label: text()
  order: 0
---

## Signature

`text()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Adds text columns to table definition.
In MySQL databases, you can specify different text sizes:
- Regular TEXT (65KB) - default when no size is specified
- MEDIUMTEXT (16MB) - specify size="mediumtext"
- LONGTEXT (4GB) - specify size="longtext"
For other database engines, the size parameter is ignored and the default text type is used.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `any` | no | — |  |
| `allowNull` | `boolean` | no | — |  |
| `size` | `string` | no | — |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a single text column to a table
t.text(&quot;body&quot;);

// 2. Add multiple text columns at once
t.text(&quot;summary,description,notes&quot;);

// 3. Add a text column that defaults to an empty string and disallows nulls
t.text(columnNames=&quot;bio&quot;, default=&quot;&quot;, allowNull=false);

// 4. Add a MEDIUMTEXT column in MySQL (16MB capacity; ignored on other databases)
t.text(columnNames=&quot;content&quot;, size=&quot;mediumtext&quot;);

// 5. Add a LONGTEXT column in MySQL (4GB capacity; ignored on other databases)
t.text(columnNames=&quot;rawHtml&quot;, size=&quot;longtext&quot;);

// 6. Full migration example using text() inside createTable
t = createTable(&quot;articles&quot;);
t.string(&quot;title&quot;);
t.text(&quot;body&quot;);
t.text(columnNames=&quot;excerpt&quot;, allowNull=true);
t.timestamps();
t.create();
</code></pre>
