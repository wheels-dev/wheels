---
title: removeRecord()
description: "Used to delete specific records from a database table within a migration CFC. This is useful when you need to clean up obsolete data, remove test data, or corre"
sidebar:
  label: removeRecord()
  order: 0
---

## Signature

`removeRecord()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Used to delete specific records from a database table within a migration CFC. This is useful when you need to clean up obsolete data, remove test data, or correct records as part of a schema migration. You can optionally provide a where clause to target specific rows. If no where clause is provided, the behavior depends on the database; usually, no records are removed unless explicitly specified. Only available in a migration CFC.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to remove the record from |
| `where` | `string` | no | — | The where clause, i.e id = 123 |

## Examples

<pre><code class='javascript'>1. Remove a specific record by ID
removeRecord(table=&quot;users&quot;, where=&quot;id = 42&quot;);

2. Remove multiple records matching a condition
removeRecord(table=&quot;orders&quot;, where=&quot;status = 'cancelled'&quot;);

3. Remove all records from a table (use with caution)
removeRecord(table=&quot;temporary_data&quot;, where=&quot;1=1&quot;);
</code></pre>
