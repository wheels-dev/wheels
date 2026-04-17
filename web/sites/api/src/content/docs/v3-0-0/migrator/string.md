---
title: string()
description: "Used to add one or more string (VARCHAR) columns to a database table. It supports specifying default values, nullability, and a maximum length (limit). Only ava"
sidebar:
  label: string()
  order: 0
---

## Signature

`string()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Used to add one or more string (VARCHAR) columns to a database table. It supports specifying default values, nullability, and a maximum length (limit). Only available in a migrator CFC.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `limit` | `any` | no | — |  |
| `default` | `string` | no | — |  |
| `allowNull` | `boolean` | no | — |  |

## Examples

<pre><code class='javascript'>1. Add a simple string column
t.string(&quot;username&quot;);

2. Limit the length of the string
t.string(columnNames=&quot;email&quot;, limit=255);

3. Set default values
t.string(columnNames=&quot;status&quot;, default=&quot;active&quot;);

4. Multiple columns in one call
t.string(columnNames=&quot;firstName,lastName&quot;);

5. Nullable vs non-nullable
t.string(columnNames=&quot;configKey&quot;, allowNull=false);
t.string(columnNames=&quot;configValue&quot;, allowNull=true);</code></pre>
