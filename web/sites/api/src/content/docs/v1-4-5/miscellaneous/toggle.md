---
title: toggle()
description: "Assigns to the property specified the opposite of the property's current boolean value. Throws an error if the property cannot be converted to a boolean value."
sidebar:
  label: toggle()
  order: 0
---

## Signature

`toggle()` — returns `any`




## Description

Assigns to the property specified the opposite of the property's current boolean value. Throws an error if the property cannot be converted to a boolean value. Returns this object if save called internally is false.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `save` | `boolean` | yes | `true` | Argument to decide whether save the property after it has been toggled. Defaults to true. |

## Examples

<pre>toggle([ save ]) &lt;!--- Get an object, and toggle a boolean property ---&gt;
&lt;cfset user = model(&quot;user&quot;).findByKey(58)&gt;
&lt;cfset isSuccess = user.toggle(&quot;isActive&quot;)&gt;&lt;!--- returns whether the object was saved properly ---&gt;
&lt;!--- You can also use a dynamic helper for this ---&gt;
&lt;cfset isSuccess = user.toggleIsActive()&gt;</pre>
