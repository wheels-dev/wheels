---
title: changeTable()
description: "Creates a table definition object to store modifications to table properties"
sidebar:
  label: changeTable()
  order: 0
---

## Signature

`changeTable()` — returns `TableDefinition`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Creates a table definition object to store modifications to table properties
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the table to set change properties on |

</div>

## Examples

<pre><code class='javascript'>t = changeTable(name='employees');
t.string(columnNames=&quot;fullName&quot;, default=&quot;&quot;, null=true, limit=&quot;255&quot;);
t.change();
</code></pre>
