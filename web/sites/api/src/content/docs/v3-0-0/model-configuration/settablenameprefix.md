---
title: setTableNamePrefix()
description: "Allows you to add a prefix to the table name used by a model when performing SQL queries. This is useful if your database uses a consistent naming convention, s"
sidebar:
  label: setTableNamePrefix()
  order: 0
---

## Signature

`setTableNamePrefix()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Allows you to add a prefix to the table name used by a model when performing SQL queries. This is useful if your database uses a consistent naming convention, such as <code>tblUsers</code> instead of <code>Users</code>. By default, Wheels infers the table name from the model name (e.g., User -> users). Using a prefix ensures that all queries automatically reference the correctly prefixed table.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `prefix` | `string` | yes | — | A prefix to prepend to the table name. |

## Examples

<pre><code class='javascript'>1. Basic prefix
// In app/models/User.cfc
function config(){
    // All queries will now target 'tblUsers' instead of 'users'
    setTableNamePrefix(&quot;tbl&quot;);
}

2. Using a custom prefix for multiple models
// app/models/Product.cfc
function config(){
    setTableNamePrefix(&quot;tbl&quot;);
}

// app/models/Order.cfc
function config(){
    setTableNamePrefix(&quot;tbl&quot;);
}</code></pre>
