---
title: findLastOne()
description: "Fetches the last record ordered by primary key value."
sidebar:
  label: findLastOne()
  order: 0
---

## Signature

`findLastOne()` — returns `any`

**Available in:** `model`
**Category:** Read Functions

## Description

Fetches the last record ordered by primary key value.
Use the <code>property</code> argument to order by something else.
Returns a model object. Formerly known as findLast.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Name of the property to order by. This argument is also aliased as `properties`. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the last user record (ordered by primary key descending)
lastUser = model(&quot;User&quot;).findLastOne();
// Returns a User object for the record with the highest primary key, or false if none exist.

// 2. Get the most recently created post by ordering on a different property
latestPost = model(&quot;Post&quot;).findLastOne(property=&quot;createdAt&quot;);
// Returns the Post object with the latest createdAt value.

// 3. Get the last active product, using a where clause alongside the property order
lastActive = model(&quot;Product&quot;).findLastOne(property=&quot;updatedAt&quot;, where=&quot;isActive = 1&quot;);
// Returns the most recently updated active product, or false if none exist.
</code></pre>
