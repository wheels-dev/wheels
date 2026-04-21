---
title: passwordField()
description: "Builds and returns a string containing a password field form control based on the supplied objectName and property. Note: Pass any additional arguments like cla"
sidebar:
  label: passwordField()
  order: 0
---

## Signature

`passwordField()` — returns `any`




## Description

Builds and returns a string containing a password field form control based on the supplied objectName and property. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | See documentation for textField. |
| `property` | `string` | yes | — | See documentation for textField. |
| `association` | `string` | yes | — | See documentation for textfield. |
| `position` | `string` | yes | — | See documentation for textfield. |
| `label` | `string` | yes | `useDefaultLabel` | See documentation for textField |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |
| `errorElement` | `string` | yes | `span` | See documentation for textField. |
| `errorClass` | `string` | yes | `fieldWithErrors` | See documentation for textField. |

</div>

## Examples

<pre>&lt;!--- Provide a `label` and the required `objectName` and `property` ---&gt;
&lt;cfoutput&gt;
    #passwordField(label=&quot;Password&quot;, objectName=&quot;user&quot;, property=&quot;password&quot;)#
&lt;/cfoutput&gt;

&lt;!--- Display fields for passwords provided by the `passwords` association and nested properties ---&gt;
&lt;fieldset&gt;
	&lt;legend&gt;Passwords&lt;/legend&gt;
	&lt;cfloop from=&quot;1&quot; to=&quot;##ArrayLen(user.passwords)##&quot; index=&quot;i&quot;&gt;
		#passwordField(label=&quot;Password ####i##&quot;, objectName=&quot;user&quot;, association=&quot;passwords&quot;, position=i, property=&quot;password&quot;)#
	&lt;/cfloop&gt;
&lt;/fieldset&gt;</pre>
