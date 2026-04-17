---
title: table()
description: "Used to tell Wheels which database table a model should connect to. Normally, Wheels automatically maps a model name to a plural table name (for example, a mode"
sidebar:
  label: table()
  order: 0
---

## Signature

`table()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Used to tell Wheels which database table a model should connect to. Normally, Wheels automatically maps a model name to a plural table name (for example, a model named <code>User</code> maps to the <code>users</code> table). However, when your database uses custom naming conventions that do not match the Wheels defaults, you can override the mapping by explicitly specifying the table name with <code>table()</code>. If you want a model to not be tied to any database table at all, you can set <code>table(false)</code>. This is useful for models that are used purely for logic, service layers, or scenarios where the model acts as a data wrapper without persistence.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `any` | yes | — | Name of the table to map this model to. |

## Examples

<pre><code class='javascript'>1. Basic override for custom table name
// In app/models/User.cfc
function config() {
 // Tell Wheels to use the `tbl_USERS` table instead of the default `users`.
 table(&quot;tbl_USERS&quot;);
}

2. Using a table with a completely different name
// In app/models/Order.cfc
function config() {
 // Map the Order model to a table named `sales_transactions`.
 table(&quot;sales_transactions&quot;);
}

3. Disabling table mapping for a non-database model
// In app/models/Notification.cfc
function config() {
 // This model will not connect to any table.
 table(false);
}

4. Working with legacy naming conventions
// In app/models/Product.cfc
function config() {
 // The database uses uppercase with prefixes for tables.
 table(&quot;LEGACY_PRODUCTS_TABLE&quot;);
}
</code></pre>
