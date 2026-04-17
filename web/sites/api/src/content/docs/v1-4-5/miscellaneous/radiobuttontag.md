---
title: radioButtonTag()
description: "Builds and returns a string containing a radio button form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, and"
sidebar:
  label: radioButtonTag()
  order: 0
---

## Signature

`radioButtonTag()` — returns `any`




## Description

Builds and returns a string containing a radio button form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `value` | `string` | yes | — | See documentation for textFieldTag. |
| `checked` | `boolean` | yes | `false` | Whether or not to check the radio button by default. |
| `label` | `string` | yes | — | See documentation for textField. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |

## Examples

<pre>&lt;!--- Basic usage usually involves a `label`, `name`, `value`, and `checked` value ---&gt;
&lt;cfoutput&gt;
	&lt;fieldset&gt;
		&lt;legend&gt;Gender&lt;/legend&gt;
		#radioButtonTag(name=&quot;gender&quot;, value=&quot;m&quot;, label=&quot;Male&quot;, checked=true)#&lt;br&gt;
		#radioButtonTag(name=&quot;gender&quot;, value=&quot;f&quot;, label=&quot;Female&quot;)#
	&lt;/fieldset&gt;
&lt;/cfoutput&gt;</pre>
