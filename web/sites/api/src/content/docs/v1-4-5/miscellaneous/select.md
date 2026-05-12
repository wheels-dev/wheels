---
title: select()
description: "Builds and returns a string containing a select form control based on the supplied objectName and property. Note: Pass any additional arguments like class, rel,"
sidebar:
  label: select()
  order: 0
---

## Signature

`select()` — returns `any`




## Description

Builds and returns a string containing a select form control based on the supplied objectName and property. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | See documentation for textField. |
| `property` | `string` | yes | — | See documentation for textField. |
| `association` | `string` | yes | — | See documentation for textfield. |
| `position` | `string` | yes | — | See documentation for textfield. |
| `options` | `any` | yes | — | A collection to populate the select form control with. Can be a query recordset or an array of objects. |
| `includeBlank` | `any` | yes | `false` | Whether to include a blank option in the select form control. Pass true to include a blank line or a string that should represent what display text should appear for the empty value (for example, "- Select One -"). |
| `valueField` | `string` | yes | — | The column or property to use for the value of each list element. Used only when a query or array of objects has been supplied in the options argument. |
| `textField` | `string` | yes | — | The column or property to use for the value of each list element that the end user will see. Used only when a query or array of objects has been supplied in the options argument. |
| `label` | `string` | yes | `useDefaultLabel` | See documentation for textField. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |
| `errorElement` | `string` | yes | `span` | See documentation for textField. |
| `errorClass` | `string` | yes | `fieldWithErrors` | See documentation for textField. |

</div>

## Examples

<pre>&lt;!--- Example 1: Basic `select` field with `label` and required `objectName` and `property` arguments ---&gt;
&lt;!--- - Controller code ---&gt;
&lt;cfset authors = model(&quot;author&quot;).findAll()&gt;

&lt;!--- - View code ---&gt;
&lt;cfoutput&gt;
    &lt;p&gt;#select(objectName=&quot;book&quot;, property=&quot;authorId&quot;, options=authors)#&lt;/p&gt;
&lt;/cfoutput&gt;

&lt;!--- Example 2: Shows `select` fields for selecting order statuses for all shipments provided by the `orders` association and nested properties ---&gt;
&lt;!--- - Controller code ---&gt;
&lt;cfset shipment = model(&quot;shipment&quot;).findByKey(key=params.key, where=&quot;shipments.statusId=##application.NEW_STATUS_ID##&quot;, include=&quot;order&quot;)&gt;
&lt;cfset statuses = model(&quot;status&quot;).findAll(order=&quot;name&quot;)&gt;

&lt;!--- - View code ---&gt;
&lt;cfoutput&gt;
	&lt;cfloop from=&quot;1&quot; to=&quot;##ArrayLen(shipments.orders)##&quot; index=&quot;i&quot;&gt;
		#select(label=&quot;Order #shipments.orders[i].orderNum#&quot;, objectName=&quot;shipment&quot;, association=&quot;orders&quot;, position=i, property=&quot;statusId&quot;, options=statuses)#
	&lt;/cfloop&gt;
&lt;/cfoutput&gt;</pre>
