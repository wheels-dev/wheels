---
title: removeIndex()
description: "Remove a database index"
sidebar:
  label: removeIndex()
  order: 0
---

## Signature

`removeIndex()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Remove a database index
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the index operation on |
| `indexName` | `string` | yes | — | the name of the index to remove |

</div>

## Examples

<pre><code class='javascript'>removeIndex(table='members',indexName='members_username');
</code></pre>
