---
title: setProperties()
description: "Allows you to set all the properties of an object at once by passing in a structure with keys matching the property names."
sidebar:
  label: setProperties()
  order: 0
---

## Signature

`setProperties()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Allows you to set all the properties of an object at once by passing in a structure with keys matching the property names.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `struct` | no | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |

</div>

## Examples

<pre><code class='javascript'>// 1. Update properties from a form post struct
user = model(&quot;User&quot;).findByKey(1);
user.setProperties(params.user);

// 2. Pass a struct literal directly to set multiple properties at once
user = model(&quot;User&quot;).findByKey(1);
user.setProperties({firstName: &quot;Jane&quot;, lastName: &quot;Doe&quot;, email: &quot;jane@example.com&quot;});
user.save();

// 3. Use named arguments instead of a struct (named args are merged with the properties struct)
user = model(&quot;User&quot;).findByKey(1);
user.setProperties(firstName=&quot;John&quot;, lastName=&quot;Smith&quot;);
user.save();
</code></pre>
