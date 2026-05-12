---
title: nestedProperties()
description: "Allows nested objects, arrays, or structs associated with a model to be automatically set from incoming params or other generated data. This is particularly use"
sidebar:
  label: nestedProperties()
  order: 0
---

## Signature

`nestedProperties()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Allows nested objects, arrays, or structs associated with a model to be automatically set from incoming params or other generated data. This is particularly useful when you have hasMany or belongsTo associations and want to manage them directly when saving the parent object.



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

<pre><code class='javascript'>1. Basic nested association with auto-save
// app/models/User.cfc
function config(){
    hasMany(&quot;groupEntitlements&quot;);

    // Allow nested save of `groupEntitlements` when user is saved
    nestedProperties(association=&quot;groupEntitlements&quot;);
}

// Controller code
user = model(&quot;User&quot;).findByKey(1);
user.groupEntitlements = [
    {groupId=1, role=&quot;admin&quot;},
    {groupId=2, role=&quot;editor&quot;}
];
user.save(); 
// Both the user and nested groupEntitlements are saved automatically

2. Allow deletion of nested objects
function config(){
    hasMany(&quot;groupEntitlements&quot;);

    // Enable deletion via `_delete` flag
    nestedProperties(association=&quot;groupEntitlements&quot;, allowDelete=true);
}

// Example params
params.user.groupEntitlements = [
    {id=10, _delete=true},
    {groupId=3, role=&quot;viewer&quot;}
];

user = model(&quot;User&quot;).findByKey(params.user.id);
user.setProperties(params.user);
user.save();
// The first nested object (id=10) is deleted, the second is saved
</code></pre>
