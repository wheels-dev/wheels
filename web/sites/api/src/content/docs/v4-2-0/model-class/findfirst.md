---
title: findFirst()
description: "Fetches the first record ordered by primary key value."
sidebar:
  label: findFirst()
  order: 0
---

## Signature

`findFirst()` — returns `any`

**Available in:** `model`
**Category:** Read Functions

## Description

Fetches the first record ordered by primary key value.
Use the <code>property</code> argument to order by something else.
Returns a model object.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | `[runtime expression]` | Name of the property to order by. This argument is also aliased as `properties`. |
| `$sort` | `string` | no | `ASC` |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the first user record (ordered by primary key ascending)
user = model(&quot;User&quot;).findFirst();
// Returns the model object with the lowest primary key value, or false if no records exist.

// 2. Get the first user ordered by a specific property
user = model(&quot;User&quot;).findFirst(property=&quot;createdAt&quot;);
// Returns the oldest user (lowest createdAt value).

// 3. Get the first active user ordered by last name, then first name
user = model(&quot;User&quot;).findFirst(properties=&quot;lastName,firstName&quot;, where=&quot;active = 1&quot;);
// Equivalent to: ORDER BY lastName ASC, firstName ASC with a WHERE clause applied.
// Returns a model object, or false if no matching record is found.
</code></pre>
