---
title: textArea()
description: "Builds and returns a string containing a text area field form control based on the supplied objectName and property. Note: Pass any additional arguments like cl"
sidebar:
  label: textArea()
  order: 0
---

## Signature

`textArea()` — returns `any`




## Description

Builds and returns a string containing a text area field form control based on the supplied objectName and property. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | See documentation for textField. |
| `property` | `string` | yes | — | See documentation for textField. |
| `association` | `string` | yes | — | See documentation for textfield. |
| `position` | `string` | yes | — | See documentation for textfield. |
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

<pre>&lt;!--- Provide `label` and required `objectName` and `property` ---&gt;
&lt;cfoutput&gt;
    #textArea(label=&quot;Overview&quot;, objectName=&quot;article&quot;, property=&quot;overview&quot;)#
&lt;/cfoutput&gt;

&lt;!--- Display fields for photos provided by the `screenshots` association and nested properties ---&gt;
&lt;fieldset&gt;
	&lt;legend&gt;Screenshots&lt;/legend&gt;
	&lt;cfloop from=&quot;1&quot; to=&quot;#ArrayLen(site.screenshots)#&quot; index=&quot;i&quot;&gt;
		#fileField(label=&quot;File #i#&quot;, objectName=&quot;site&quot;, association=&quot;screenshots&quot;, position=i, property=&quot;file&quot;)#
		#textArea(label=&quot;Caption ####i##&quot;, objectName=&quot;site&quot;, association=&quot;screenshots&quot;, position=i, property=&quot;caption&quot;)#
	&lt;/cfloop&gt;
&lt;/fieldset&gt;</pre>
