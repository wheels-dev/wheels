---
title: setPrimaryKey()
description: "Allows you to pass in the name(s) of the property(s) that should be used as the primary key(s)."
sidebar:
  label: setPrimaryKey()
  order: 0
---

## Signature

`setPrimaryKey()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Allows you to pass in the name(s) of the property(s) that should be used as the primary key(s).
Pass as a list if defining a composite primary key.
This function is also aliased as <code>setPrimaryKeys()</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Property (or list of properties) to set as the primary key. |

</div>

## Examples

<pre><code class='javascript'>// 1. In `models/User.cfc`, define the primary key as a column called `userID`
//    instead of the Wheels default of `id`.
component extends=&quot;Model&quot; {
	function config() {
		setPrimaryKey(&quot;userID&quot;);
	}
}

// 2. Define a composite primary key for a join model using two columns.
//    `setPrimaryKeys()` is an alias for `setPrimaryKey()` that reads more
//    naturally when multiple properties are involved.
component extends=&quot;Model&quot; {
	function config() {
		table(&quot;users_roles&quot;);
		setPrimaryKeys(&quot;userID,roleID&quot;);
	}
}
</code></pre>
