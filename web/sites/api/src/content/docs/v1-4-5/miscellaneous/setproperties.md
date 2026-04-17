---
title: setProperties()
description: "Allows you to set all the properties of an object at once by passing in a structure with keys matching the property names."
sidebar:
  label: setProperties()
  order: 0
---

## Signature

`setProperties()` — returns `any`




## Description

Allows you to set all the properties of an object at once by passing in a structure with keys matching the property names.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `struct` | yes | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |

## Examples

<pre>setProperties([ properties ]) &lt;!--- Update the properties of the object with the params struct containing the values of a form post ---&gt;
&lt;cfset user = model(&quot;user&quot;).findByKey(1)&gt;
&lt;cfset user.setProperties(params.user)&gt;</pre>
