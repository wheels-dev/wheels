---
title: properties()
description: "Returns a structure containing all the properties of a model object, where the keys are the property (column) names and the values are the current values for th"
sidebar:
  label: properties()
  order: 0
---

## Signature

`properties()` — returns `struct`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a structure containing all the properties of a model object, where the keys are the property (column) names and the values are the current values for that object. This is useful when you want to inspect all the attributes of a record at once, serialize data, or debug object state. By default, properties() includes nested or associated properties (such as related objects). You can control this behavior using the returnIncluded argument to exclude them if you only want the direct properties of the object.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `returnIncluded` | `boolean` | no | `true` | Whether to return nested properties or not. |

## Examples

<pre><code class='javascript'>1. Get all properties for a user object
user = model(&quot;user&quot;).findByKey(1);
props = user.properties();

2. Exclude nested/associated properties
user = model(&quot;user&quot;).findByKey(1);
props = user.properties(returnIncluded=false);

3. Iterate through properties
user = model(&quot;user&quot;).findByKey(2);
props = user.properties();
for (key in props) {
    writeOutput(&quot;#key#: #props[key]#&lt;br&gt;&quot;);
}

4. Convert properties to JSON for API output
user = model(&quot;user&quot;).findByKey(3);
props = user.properties(returnIncluded=false);
jsonData = serializeJSON(props);
</code></pre>
