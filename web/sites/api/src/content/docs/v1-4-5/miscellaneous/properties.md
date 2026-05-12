---
title: properties()
description: "Returns a structure of all the properties with their names as keys and the values of the property as values."
sidebar:
  label: properties()
  order: 0
---

## Signature

`properties()` — returns `any`




## Description

Returns a structure of all the properties with their names as keys and the values of the property as values.


## Examples

<pre>properties() &lt;!--- Get a structure of all the properties for an object ---&gt;
&lt;cfset user = model(&quot;user&quot;).findByKey(1)&gt;
&lt;cfset props = user.properties()&gt;</pre>
