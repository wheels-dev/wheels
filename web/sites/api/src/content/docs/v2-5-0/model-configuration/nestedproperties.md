---
title: nestedProperties()
description: "Allows for nested objects, structs, and arrays to be set from params and other generated data."
sidebar:
  label: nestedProperties()
  order: 0
---

## Signature

`nestedProperties()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Allows for nested objects, structs, and arrays to be set from params and other generated data.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `association` | `string` | no | — | The association (or list of associations) you want to allow to be set through the params. This argument is also aliased as `associations`. |
| `autoSave` | `boolean` | no | `true` | Whether to save the association(s) when the parent object is saved. |
| `allowDelete` | `boolean` | no | `false` | Set this to `true` to tell CFWheels to look for the property `_delete` in your model. If present and set to a value that evaluates to true, the model will be deleted when saving the parent. |
| `sortProperty` | `string` | no | — | Set this to a property on the object that you would like to sort by. The property should be numeric, should start with 1, and should be consecutive. Only valid with `hasMany` associations. |
| `rejectIfBlank` | `string` | no | — | A list of properties that should not be blank. If any of the properties are blank, any CRUD operations will be rejected. |

## Examples

<pre><code class='javascript'>// In `models/User.cfc`, allow for `groupEntitlements` to be saved and deleted through the `user` object.
function config(){
	hasMany(&quot;groupEntitlements&quot;);
	nestedProperties(association=&quot;groupEntitlements&quot;, allowDelete=true);
}
</code></pre>
