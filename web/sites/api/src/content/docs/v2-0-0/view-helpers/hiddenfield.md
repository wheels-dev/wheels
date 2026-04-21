---
title: hiddenField()
description: "Builds and returns a string containing a hidden field form control based on the supplied objectName and property."
sidebar:
  label: hiddenField()
  order: 0
---

## Signature

`hiddenField()` — returns `string`

**Available in:** `controller`
**Category:** Form Object Functions

## Description

Builds and returns a string containing a hidden field form control based on the supplied objectName and property.
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | The variable name of the object to build the form control for. |
| `property` | `string` | yes | — | The name of the property to use in the form control. |
| `association` | `string` | no | — | The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and CFWheels will figure it out. |
| `position` | `string` | no | — | The position used when referencing a hasMany relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and CFWheels will figure it out. |
| `encode` | `boolean` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre>&lt;!--- Provide an `objectName` and `property` ---&gt;
#hiddenField(objectName=&quot;user&quot;, property=&quot;id&quot;)#</pre>
