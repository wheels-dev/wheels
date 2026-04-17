---
title: uniqueidentifier()
description: "Used to add one or more UUID (Universally Unique Identifier) columns to a table definition. These columns are useful for generating globally unique keys for rec"
sidebar:
  label: uniqueidentifier()
  order: 0
---

## Signature

`uniqueidentifier()` — returns `any`

**Available in:** `tabledefinition`
**Category:** Table Definition Functions

## Description

Used to add one or more UUID (Universally Unique Identifier) columns to a table definition. These columns are useful for generating globally unique keys for records instead of relying on auto-incrementing integers. By default, the function uses newid() to populate the column with a UUID, and you can also configure whether the column allows NULL. Only available in a migrator CFC.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `columnNames` | `string` | no | — |  |
| `default` | `string` | no | `newid()` |  |
| `allowNull` | `boolean` | no | — |  |

## Examples

<pre><code class='javascript'>1. Add a single UUID column
t.uniqueidentifier(&quot;uuid&quot;)

2. Add multiple UUID columns
t.uniqueidentifier(&quot;uuid, externalId&quot;)

3. Add a UUID column with default UUID generation
t.uniqueidentifier(columnNames=&quot;uuid&quot;, default=&quot;newid()&quot;)

4. Add a nullable UUID column
t.uniqueidentifier(columnNames=&quot;optionalUuid&quot;, allowNull=true)
</code></pre>
