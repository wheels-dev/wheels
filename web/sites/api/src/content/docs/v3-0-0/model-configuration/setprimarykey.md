---
title: setPrimaryKey()
description: "The setPrimaryKey() function allows you to define which property (or properties) of a model represent the primary key in the database. This is crucial for Wheel"
sidebar:
  label: setPrimaryKey()
  order: 0
---

## Signature

`setPrimaryKey()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

The setPrimaryKey() function allows you to define which property (or properties) of a model represent the primary key in the database. This is crucial for Wheels to correctly handle CRUD operations, updates, and record lookups. For single-column primary keys, pass the property name as a string. For composite primary keys (multiple columns together form the key), pass a comma-separated list of property names. Alias: <code>setPrimaryKeys()</code>



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Property (or list of properties) to set as the primary key. |

</div>

## Examples

<pre><code class='javascript'>1. Single primary key
component extends=&quot;Model&quot; {
    function config() {
        // The primary key for this table is `userID`
        setPrimaryKey(&quot;userID&quot;);
    }
}

2. Composite primary key
component extends=&quot;Model&quot; {
    function config() {
        // The combination of `orderID` and `productID` uniquely identifies a record
        setPrimaryKey(&quot;orderID,productID&quot;);
    }
}

3. Using the alias setPrimaryKeys()
component extends=&quot;Model&quot; {
    function config() {
        // Alias works the same as `setPrimaryKey()`
        setPrimaryKeys(&quot;customerID&quot;);
    }
}</code></pre>
