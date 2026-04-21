---
title: radioButton()
description: "Builds and returns a string containing a radio button form control based on the supplied objectName and property. Note: Pass any additional arguments like class"
sidebar:
  label: radioButton()
  order: 0
---

## Signature

`radioButton()` — returns `any`




## Description

Builds and returns a string containing a radio button form control based on the supplied objectName and property. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `objectName` | `any` | yes | — | See documentation for textField. |
| `property` | `string` | yes | — | See documentation for textField. |
| `association` | `string` | yes | — | See documentation for textfield. |
| `position` | `string` | yes | — | See documentation for textfield. |
| `tagValue` | `string` | yes | — | The value of the radio button when selected. |
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

<pre>&lt;!--- Basic example view code ---&gt;
&lt;cfoutput&gt;
	&lt;fieldset&gt;
		&lt;legend&gt;Gender&lt;/legend&gt;
	    #radioButton(objectName=&quot;user&quot;, property=&quot;gender&quot;, tagValue=&quot;m&quot;, label=&quot;Male&quot;)#&lt;br /&gt;
        #radioButton(objectName=&quot;user&quot;, property=&quot;gender&quot;, tagValue=&quot;f&quot;, label=&quot;Female&quot;)#
	&lt;/fieldset&gt;
&lt;/cfoutput&gt;

&lt;!--- Shows radio buttons for selecting the genders for all committee members provided by the `members` association and nested properties ---&gt;
&lt;cfoutput&gt;
	&lt;cfloop from=&quot;1&quot; to=&quot;#ArrayLen(committee.members)#&quot; index=&quot;i&quot;&gt;
		&lt;div&gt;
			&lt;h3&gt;#committee.members[i].fullName#:&lt;/h3&gt;
			&lt;div&gt;
				#radioButton(objectName=&quot;committee&quot;, association=&quot;members&quot;, position=i, property=&quot;gender&quot;, tagValue=&quot;m&quot;, label=&quot;Male&quot;)#&lt;br /&gt;
				#radioButton(objectName=&quot;committee&quot;, association=&quot;members&quot;, position=i, property=&quot;gender&quot;, tagValue=&quot;f&quot;, label=&quot;Female&quot;)#
			&lt;/div&gt;
		&lt;/div&gt;
	&lt;/cfloop&gt;
&lt;/cfoutput&gt;</pre>
