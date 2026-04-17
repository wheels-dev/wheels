---
title: textField()
description: "Builds and returns a string containing a text field form control based on the supplied objectName and property. Note: Pass any additional arguments like class,"
sidebar:
  label: textField()
  order: 0
---

## Signature

`textField()` — returns `any`




## Description

Builds and returns a string containing a text field form control based on the supplied objectName and property. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | The variable name of the object to build the form control for. |
| `property` | `string` | yes | — | The name of the property to use in the form control. |
| `association` | `string` | yes | — | The name of the association that the property is located on. Used for building nested forms that work with nested properties. If you are building a form with deep nesting, simply pass in a list to the nested object, and CFWheels will figure it out. |
| `position` | `string` | yes | — | The position used when referencing a hasMany relationship in the association argument. Used for building nested forms that work with nested properties. If you are building a form with deep nestings, simply pass in a list of positions, and CFWheels will figure it out. |
| `label` | `string` | yes | `useDefaultLabel` | The label text to use in the form control. |
| `labelPlacement` | `string` | yes | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | yes | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | yes | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | yes | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | yes | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `errorElement` | `string` | yes | `span` | HTML tag to wrap the form control with when the object contains errors. |
| `errorClass` | `string` | yes | `fieldWithErrors` | The class name of the HTML tag that wraps the form control when there are errors. |
| `type` | `string` | yes | `text` | Input type attribute. Common examples in HTML5 and later are text (default), email, tel, and url. |
| `labelClass` | `string` | yes | — | String added to the label's class. |

## Examples

<pre>&lt;!--- Provide a `label` and the required `objectName` and `property` ---&gt;
&lt;cfoutput&gt;
    #textField(label=&quot;First Name&quot;, objectName=&quot;user&quot;, property=&quot;firstName&quot;)#
&lt;/cfoutput&gt;

&lt;!--- Display fields for phone numbers provided by the `phoneNumbers` association and nested properties ---&gt;
&lt;fieldset&gt;
	&lt;legend&gt;gt;Phone Numbers&lt;/legend&gt;
	&lt;cfloop from=&quot;1&quot; to=&quot;##ArrayLen(contact.phoneNumbers)##&quot; index=&quot;i&quot;&gt;
		#textField(label=&quot;Phone ####i##&quot;, objectName=&quot;contact&quot;, association=&quot;phoneNumbers&quot;, position=i, property=&quot;phoneNumber&quot;)#
	&lt;/cfloop&gt;
&lt;/fieldset&gt;</pre>
