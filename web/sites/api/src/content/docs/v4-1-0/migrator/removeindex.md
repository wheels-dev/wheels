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

<pre><code class='javascript'>// 1. Remove an index by its name
removeIndex(table=&quot;members&quot;, indexName=&quot;members_username&quot;);

// 2. Remove a compound index created on multiple columns
// (index was previously added as &quot;orders_customerid_createdat&quot;)
removeIndex(table=&quot;orders&quot;, indexName=&quot;orders_customerid_createdat&quot;);

// 3. Typical down() migration reversing an addIndex call
component extends=&quot;wheels.Migrator&quot; {
    function up() {
        addIndex(table=&quot;articles&quot;, columnNames=&quot;slug&quot;, unique=true, indexName=&quot;articles_slug&quot;);
    }
    function down() {
        removeIndex(table=&quot;articles&quot;, indexName=&quot;articles_slug&quot;);
    }
}
</code></pre>
