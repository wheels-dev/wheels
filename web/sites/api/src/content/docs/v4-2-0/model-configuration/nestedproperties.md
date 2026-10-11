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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `association` | `string` | no | — | The association (or list of associations) you want to allow to be set through the params. This argument is also aliased as `associations`. |
| `autoSave` | `boolean` | no | `true` | Whether to save the association(s) when the parent object is saved. |
| `allowDelete` | `boolean` | no | `false` | Set this to `true` to tell Wheels to look for the property `_delete` in your model. If present and set to a value that evaluates to true, the model will be deleted when saving the parent. |
| `sortProperty` | `string` | no | — | Set this to a property on the object that you would like to sort by. The property should be numeric, should start with 1, and should be consecutive. Only valid with `hasMany` associations. |
| `rejectIfBlank` | `string` | no | — | A list of properties that should not be blank. If any of the properties are blank, any CRUD operations will be rejected. |

</div>

## Examples

<pre><code class='javascript'>// 1. In `models/User.cfc`, allow `groupEntitlements` to be saved and deleted through the `user` object.
function config() {
	hasMany(&quot;groupEntitlements&quot;);
	nestedProperties(association=&quot;groupEntitlements&quot;, allowDelete=true);
}

// 2. Allow nested `addresses` to be saved but not auto-saved with the parent; also reject blank `street` values.
function config() {
	hasMany(&quot;addresses&quot;);
	nestedProperties(association=&quot;addresses&quot;, autoSave=false, rejectIfBlank=&quot;street&quot;);
}

// 3. Allow nested `lineItems` with a sort order driven by the `position` property, and enable deletion.
function config() {
	hasMany(&quot;lineItems&quot;);
	nestedProperties(association=&quot;lineItems&quot;, allowDelete=true, sortProperty=&quot;position&quot;);
}

// 4. Enable nested properties for multiple associations at once.
function config() {
	hasOne(&quot;profile&quot;);
	hasMany(&quot;phoneNumbers&quot;);
	nestedProperties(associations=&quot;profile,phoneNumbers&quot;);
}
</code></pre>
