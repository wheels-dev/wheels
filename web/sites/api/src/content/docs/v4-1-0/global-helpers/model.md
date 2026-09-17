---
title: model()
description: "Returns a reference to the requested model so that class level methods can be called on it."
sidebar:
  label: model()
  order: 0
---

## Signature

`model()` — returns `any`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Returns a reference to the requested model so that class level methods can be called on it.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the model to get a reference to. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get a reference to the User model and call a class-level finder on it
user = model(&quot;User&quot;).findByKey(params.key);

// 2. Find all active users by calling findAll() on the model reference
activeUsers = model(&quot;User&quot;).findAll(where=&quot;active = 1&quot;, order=&quot;lastName&quot;);

// 3. Create a new record via the model reference
newPost = model(&quot;Post&quot;).new(title=params.title, body=params.body);
newPost.save();

// 4. Count records using the model reference
totalOrders = model(&quot;Order&quot;).count(where=&quot;status = 'pending'&quot;);
</code></pre>
