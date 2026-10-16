---
title: properties()
description: "Returns a structure of all the properties with their names as keys and the values of the property as values."
sidebar:
  label: properties()
  order: 0
---

## Signature

`properties()` — returns `struct`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a structure of all the properties with their names as keys and the values of the property as values.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `returnIncluded` | `boolean` | no | `true` | Whether to return nested properties or not. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get all properties of a model object as a struct
user = model(&quot;User&quot;).findByKey(1);
props = user.properties();
// props -&gt; {id: 1, firstName: &quot;Jane&quot;, lastName: &quot;Doe&quot;, email: &quot;jane@example.com&quot;, createdAt: ...}

// 2. Exclude nested (included) association properties from the result
// Useful when you only want the object's own scalar properties
post = model(&quot;Post&quot;).findOne(include=&quot;comments&quot;);
ownProps = post.properties(returnIncluded=false);
// ownProps -&gt; {id: 42, title: &quot;Hello World&quot;, body: &quot;...&quot;, createdAt: ...}
// (nested `comments` array is omitted)

// 3. Use properties() to pass a model's data as a plain struct (e.g. to a service layer)
user = model(&quot;User&quot;).findByKey(session.userId);
userService.syncUser(user.properties());
</code></pre>
