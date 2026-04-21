---
title: select()
description: "Builds and returns a string containing a select form control based on the supplied objectName and property."
sidebar:
  label: select()
  order: 0
---

## Signature

`select()` — returns `string`

**Available in:** `controller`
**Category:** Form Object Functions

## Description

Builds and returns a string containing a select form control based on the supplied objectName and property.
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | The variable name of the object to build the form control for. |
| `property` | `string` | yes | — | The name of the property to use in the form control. |
| `association` | `string` | no | — | The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and CFWheels will figure it out. |
| `position` | `string` | no | — | The position used when referencing a hasMany relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and CFWheels will figure it out. |
| `options` | `any` | no | — | A collection to populate the select form control with. Can be a query recordset or an array of objects. |
| `includeBlank` | `any` | no | `false` | Whether to include a blank option in the select form control. Pass true to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -"). |
| `valueField` | `string` | no | — | The column or property to use for the value of each list element. Used only when a query or array of objects has been supplied in the options argument.  Required when specifying `textField` |
| `textField` | `string` | no | — | The column or property to use for the value of each list element that the end user will see. Used only when a query or array of objects has been supplied in the options argument. Required when specifying `valueField` |
| `label` | `string` | no | `useDefaultLabel` | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `errorElement` | `string` | no | `span` | HTML tag to wrap the form control with when the object contains errors. |
| `errorClass` | `string` | no | `field-with-errors` | The class name of the HTML tag that wraps the form control when there are errors. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>// Example 1: Basic `select` field with `label` and required `objectName` and `property` arguments
// - Controller code
authors = model(&quot;author&quot;).findAll();

&lt;!--- View code---&gt;
#select(objectName=&quot;book&quot;, property=&quot;authorId&quot;, options=authors)#

&lt;!---
	Do this when CFWheels isn't grabbing the correct values for the `option`s' values and display texts
	Note that `valueField` and `textField` are both required when using this option
---&gt;
#select(objectName=&quot;book&quot;, property=&quot;authorId&quot;, options=authors, valueField=&quot;id&quot;, textField=&quot;authorfullname&quot;)#

// Example 2: Shows `select` fields for selecting order statuses for all shipments provided by the `orders` association and nested properties
// Controller code
shipment = model(&quot;shipment&quot;).findByKey(key=params.key, where=&quot;shipments.statusId=#application.NEW_STATUS_ID#&quot;, include=&quot;order&quot;);
statuses = model(&quot;status&quot;).findAll(order=&quot;name&quot;);

&lt;!--- View code---&gt;
&lt;cfloop from=&quot;1&quot; to=&quot;#ArrayLen(shipments.orders)#&quot; index=&quot;i&quot;&gt;
	#select(label=&quot;Order #shipments.orders[i].orderNum#&quot;, objectName=&quot;shipment&quot;, association=&quot;orders&quot;, position=i, property=&quot;statusId&quot;, options=statuses)#
&lt;/cfloop&gt;
</code></pre>
