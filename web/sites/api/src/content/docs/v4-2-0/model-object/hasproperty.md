---
title: hasProperty()
description: "Returns <code>true</code> if the specified property name exists on the model."
sidebar:
  label: hasProperty()
  order: 0
---

## Signature

`hasProperty()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns <code>true</code> if the specified property name exists on the model.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

</div>

## Examples

<pre><code class='javascript'>// 1. Check whether a property exists on a new object after setting it
employee = model(&quot;Employee&quot;).new();
employee.firstName = &quot;Jane&quot;;
employee.hasProperty(&quot;firstName&quot;); // -&gt; true
employee.hasProperty(&quot;salary&quot;);    // -&gt; false (not set on this object)

// 2. Use the equivalent dynamic method (has&lt;PropertyName&gt;)
employee.hasFirstName(); // -&gt; true
employee.hasSalary();    // -&gt; false

// 3. Guard logic before accessing a property
user = model(&quot;User&quot;).findOne(where=&quot;email='jane@example.com'&quot;);
if (user.hasProperty(&quot;avatarUrl&quot;)) {
    writeOutput(user.avatarUrl);
}
</code></pre>
