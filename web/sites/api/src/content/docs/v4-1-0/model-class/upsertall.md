---
title: upsertAll()
description: "Inserts or updates multiple records in a single batch operation (upsert)."
sidebar:
  label: upsertAll()
  order: 0
---

## Signature

`upsertAll()` — returns `struct`

**Available in:** `model`
**Category:** Create Functions

## Description

Inserts or updates multiple records in a single batch operation (upsert).
Uses database-specific conflict resolution syntax (e.g., <code>ON CONFLICT ... DO UPDATE</code> for PostgreSQL/SQLite).
The <code>uniqueBy</code> argument specifies which properties form the unique constraint for conflict detection.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `records` | `array` | yes | — | Array of structs, each containing property name/value pairs. |
| `uniqueBy` | `string` | yes | — | Comma-delimited list of property names that form the unique constraint for conflict detection. |
| `timestamps` | `boolean` | no | `true` | Set to `false` to skip automatic `createdAt`/`updatedAt` timestamping. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |

</div>

## Examples

<pre><code class='javascript'>// 1. Upsert a batch of products using their SKU as the unique constraint
records = [
    {sku: &quot;WIDGET-001&quot;, name: &quot;Widget Standard&quot;, price: 9.99, stock: 100},
    {sku: &quot;WIDGET-002&quot;, name: &quot;Widget Deluxe&quot;,   price: 19.99, stock: 50},
    {sku: &quot;GADGET-001&quot;, name: &quot;Gadget Pro&quot;,       price: 49.99, stock: 25}
];
result = model(&quot;Product&quot;).upsertAll(records=records, uniqueBy=&quot;sku&quot;);
// result -&gt; {upsertedCount: 3}

// 2. Upsert with a composite unique constraint (e.g., userId + date for daily stats)
stats = [
    {userId: 1, reportDate: &quot;2024-06-01&quot;, pageViews: 42, clicks: 7},
    {userId: 2, reportDate: &quot;2024-06-01&quot;, pageViews: 18, clicks: 3}
];
result = model(&quot;DailyStat&quot;).upsertAll(records=stats, uniqueBy=&quot;userId,reportDate&quot;);
// result -&gt; {upsertedCount: 2}

// 3. Upsert without automatic timestamps (e.g., when importing legacy data)
imports = [
    {externalId: &quot;EXT-100&quot;, title: &quot;Legacy Record A&quot;, status: &quot;active&quot;},
    {externalId: &quot;EXT-101&quot;, title: &quot;Legacy Record B&quot;, status: &quot;archived&quot;}
];
result = model(&quot;ImportedRecord&quot;).upsertAll(
    records    = imports,
    uniqueBy   = &quot;externalId&quot;,
    timestamps = false
);
// result -&gt; {upsertedCount: 2}
</code></pre>
