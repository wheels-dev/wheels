---
title: addForeignKey()
description: "Add a foreign key constraint to the database, using the reference name that was used to create it"
sidebar:
  label: addForeignKey()
  order: 0
---

## Signature

`addForeignKey()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Add a foreign key constraint to the database, using the reference name that was used to create it
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the operation on |
| `referenceTable` | `string` | yes | — | The reference table name to perform the operation on |
| `column` | `string` | no | — | The column name to perform the operation on |
| `columnName` | `string` | no | — | Modern alias for `column` (consistent with the rest of the migrator surface). |
| `referenceColumn` | `string` | yes | — | The reference column name to perform the operation on |

</div>

## Examples

<pre><code class='javascript'>// 1. Add a foreign key from orders.customerId to customers.id
addForeignKey(
    table=&quot;orders&quot;,
    referenceTable=&quot;customers&quot;,
    column=&quot;customerId&quot;,
    referenceColumn=&quot;id&quot;
);

// 2. Add a foreign key from comments.postId to posts.id
addForeignKey(
    table=&quot;comments&quot;,
    referenceTable=&quot;posts&quot;,
    column=&quot;postId&quot;,
    referenceColumn=&quot;id&quot;
);

// 3. Use addForeignKey in a migration's up() and remove it in down()
// In your migration CFC:
//
// public void function up() {
//     addForeignKey(
//         table=&quot;order_items&quot;,
//         referenceTable=&quot;orders&quot;,
//         column=&quot;orderId&quot;,
//         referenceColumn=&quot;id&quot;
//     );
// }
//
// public void function down() {
//     dropForeignKey(table=&quot;order_items&quot;, keyName=&quot;FK_order_items_orders&quot;);
// }
</code></pre>
