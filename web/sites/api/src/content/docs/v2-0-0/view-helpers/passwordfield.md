---
title: passwordField()
description: "Builds and returns a string containing a password field form control based on the supplied objectName and property."
sidebar:
  label: passwordField()
  order: 0
---

## Signature

`passwordField()` — returns `string`

**Available in:** `controller`
**Category:** Form Object Functions

## Description

Builds and returns a string containing a password field form control based on the supplied objectName and property.
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



## Parameters

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

## Examples

<pre>// Provide a `label` and the required `objectName` and `property`
&lt;cfoutput&gt;
    #passwordField(label=&quot;Password&quot;, objectName=&quot;user&quot;, property=&quot;password&quot;)#
&lt;/cfoutput&gt;

// Display fields for passwords provided by the `passwords` association and nested properties
&lt;fieldset&gt;
	&lt;legend&gt;Passwords&lt;/legend&gt;
	&lt;cfloop from=&quot;1&quot; to=&quot;#ArrayLen(user.passwords)#&quot; index=&quot;i&quot;&gt;
		#passwordField(label=&quot;Password ##i#&quot;, objectName=&quot;user&quot;, association=&quot;passwords&quot;, position=i, property=&quot;password&quot;)#
	&lt;/cfloop&gt;
&lt;/fieldset&gt;</pre>
