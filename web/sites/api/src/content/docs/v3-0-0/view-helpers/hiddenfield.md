---
title: hiddenField()
description: "The hiddenField() function generates a hidden &lt;input type=\"hidden\"&gt; tag for a given model object and property. It’s commonly used to store identifiers or"
sidebar:
  label: hiddenField()
  order: 0
---

## Signature

`hiddenField()` — returns `string`

**Available in:** `controller`
**Category:** Form Object Functions

## Description

The hiddenField() function generates a hidden &lt;input type="hidden"&gt; tag for a given model object and property. It’s commonly used to store identifiers or other values that need to persist across form submissions without being visible to the user.
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | The variable name of the object to build the form control for. |
| `property` | `string` | yes | — | The name of the property to use in the form control. |
| `association` | `string` | no | — | The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and Wheels will figure it out. |
| `position` | `string` | no | — | The position used when referencing a hasMany relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and Wheels will figure it out. |
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |

## Examples

<pre><code class='javascript'>1. Basic usage with object and property
&lt;!--- Hidden field for user.id ---&gt;
#hiddenField(objectName=&quot;user&quot;, property=&quot;id&quot;)#

// Generates something like:
// &lt;input id=&quot;user-id&quot; name=&quot;user.id&quot; type=&quot;hidden&quot; value=&quot;123&quot;&gt;

2. Adding extra HTML attributes
#hiddenField(
    objectName=&quot;user&quot;,
    property=&quot;sessionToken&quot;,
    id=&quot;custom-token&quot;,
    class=&quot;hidden-tracker&quot;
)#

// &lt;input id=&quot;custom-token&quot; name=&quot;user.sessionToken&quot; type=&quot;hidden&quot; value=&quot;abc123&quot; class=&quot;hidden-tracker&quot;&gt;

3. Nested association (hasOne or belongsTo)
#hiddenField(
    objectName=&quot;order&quot;,
    property=&quot;id&quot;,
    association=&quot;customer&quot;
)#

// If an order has a customer, this binds the hidden field to order.customer.id.

4. Nested hasMany with position
#hiddenField(
    objectName=&quot;order&quot;,
    property=&quot;id&quot;,
    association=&quot;items&quot;,
    position=&quot;1&quot;
)#

// Binds to the id of the second item in the order’s items collection.
</code></pre>
