---
title: textArea()
description: "Builds and returns a string containing a text area field form control based on the supplied objectName and property."
sidebar:
  label: textArea()
  order: 0
---

## Signature

`textArea()` — returns `string`

**Available in:** `controller`
**Category:** Form Object Functions

## Description

Builds and returns a string containing a text area field form control based on the supplied objectName and property.
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | The variable name of the object to build the form control for. |
| `property` | `string` | yes | — | The name of the property to use in the form control. |
| `association` | `string` | no | — | The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and CFWheels will figure it out. |
| `position` | `string` | no | — | The position used when referencing a hasMany relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and CFWheels will figure it out. |
| `label` | `string` | no | `useDefaultLabel` | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `errorElement` | `string` | no | `span` | HTML tag to wrap the form control with when the object contains errors. |
| `errorClass` | `string` | no | `field-with-errors` | The class name of the HTML tag that wraps the form control when there are errors. |
| `encode` | `any` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre>&lt;!--- 	Provide `label` and required `objectName` and `property` ---&gt;
#textArea(label=&quot;Overview&quot;, objectName=&quot;article&quot;, property=&quot;overview&quot;)#

&lt;!--- Display fields for photos provided by the `screenshots` association and nested properties ---&gt;
&lt;fieldset&gt;
	&lt;legend&gt;Screenshots&lt;/legend&gt;
	&lt;cfloop from=&quot;1&quot; to=&quot;#ArrayLen(site.screenshots)#&quot; index=&quot;i&quot;&gt;
		#fileField(label=&quot;File #i#&quot;, objectName=&quot;site&quot;, association=&quot;screenshots&quot;, position=i, property=&quot;file&quot;)#
		#textArea(label=&quot;Caption ##i#&quot;, objectName=&quot;site&quot;, association=&quot;screenshots&quot;, position=i, property=&quot;caption&quot;)#
	&lt;/cfloop&gt;
&lt;/fieldset&gt;</pre>
