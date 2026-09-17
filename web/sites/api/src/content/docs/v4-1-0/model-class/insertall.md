---
title: insertAll()
description: "Inserts multiple records into the database in a single batch operation."
sidebar:
  label: insertAll()
  order: 0
---

## Signature

`insertAll()` — returns `struct`

**Available in:** `model`
**Category:** Create Functions

## Description

Inserts multiple records into the database in a single batch operation.
Accepts an array of structs where each struct represents a record to insert.
All structs must have the same set of keys (property names).
Batches in groups of 1000 to avoid database parameter limits.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `records` | `array` | yes | — | Array of structs, each containing property name/value pairs to insert. |
| `timestamps` | `boolean` | no | `true` | Set to `false` to skip automatic `createdAt`/`updatedAt` timestamping. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |

</div>

## Examples

<pre><code class='javascript'>// 1. Insert multiple user records in a single batch
newUsers = [
    {firstName: &quot;Alice&quot;, lastName: &quot;Smith&quot;, email: &quot;alice@example.com&quot;},
    {firstName: &quot;Bob&quot;,   lastName: &quot;Jones&quot;, email: &quot;bob@example.com&quot;},
    {firstName: &quot;Carol&quot;, lastName: &quot;White&quot;, email: &quot;carol@example.com&quot;}
];
result = model(&quot;User&quot;).insertAll(records=newUsers);
// result -&gt; {insertedCount: 3}

// 2. Insert records without automatic createdAt/updatedAt timestamps
rows = [
    {username: &quot;imported_1&quot;, score: 9800},
    {username: &quot;imported_2&quot;, score: 7450}
];
result = model(&quot;HighScore&quot;).insertAll(records=rows, timestamps=false);
// result -&gt; {insertedCount: 2}

// 3. Insert a large dataset wrapped in a single transaction, using selective cfqueryparam
products = [];
for (i = 1; i &lt;= 2500; i++) {
    arrayAppend(products, {name: &quot;Product #i#&quot;, price: RandRange(1, 999), stock: RandRange(0, 500)});
}
// Batches automatically in groups of 1000; all batches share one transaction.
result = model(&quot;Product&quot;).insertAll(
    records      = products,
    transaction  = &quot;commit&quot;,
    parameterize = &quot;price,stock&quot;
);
// result -&gt; {insertedCount: 2500}
</code></pre>
