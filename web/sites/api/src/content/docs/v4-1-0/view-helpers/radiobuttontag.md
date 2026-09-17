---
title: radioButtonTag()
description: "Builds and returns a string containing a radio button form control based on the supplied name."
sidebar:
  label: radioButtonTag()
  order: 0
---

## Signature

`radioButtonTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing a radio button form control based on the supplied name.
Note: Pass any additional arguments like <code>class</code>, <code>rel</code>, and <code>id</code>, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `value` | `string` | yes | — | Value to populate in tag's value attribute. |
| `checked` | `boolean` | no | `false` | Whether or not to check the radio button by default. |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>// 1. Basic usage with a group of radio buttons sharing the same name
&lt;cfoutput&gt;
	&lt;fieldset&gt;
		&lt;legend&gt;Gender&lt;/legend&gt;
		#radioButtonTag(name=&quot;gender&quot;, value=&quot;m&quot;, label=&quot;Male&quot;, checked=true)#
		#radioButtonTag(name=&quot;gender&quot;, value=&quot;f&quot;, label=&quot;Female&quot;)#
	&lt;/fieldset&gt;
&lt;/cfoutput&gt;

// 2. Place the label after the radio button instead of wrapping it
&lt;cfoutput&gt;
	#radioButtonTag(name=&quot;size&quot;, value=&quot;s&quot;, label=&quot;Small&quot;, labelPlacement=&quot;after&quot;)#
	#radioButtonTag(name=&quot;size&quot;, value=&quot;m&quot;, label=&quot;Medium&quot;, labelPlacement=&quot;after&quot;)#
	#radioButtonTag(name=&quot;size&quot;, value=&quot;l&quot;, label=&quot;Large&quot;, labelPlacement=&quot;after&quot;)#
&lt;/cfoutput&gt;

// 3. Loop over a query to render one radio button per option
// Controller
sizes = model(&quot;Size&quot;).findAll(order=&quot;position&quot;);

// View
&lt;cfoutput query=&quot;sizes&quot;&gt;
	#radioButtonTag(
		name   = &quot;sizeId&quot;,
		value  = sizes.id,
		label  = sizes.name,
		checked = sizes.id EQ params.sizeId
	)#
&lt;/cfoutput&gt;
</code></pre>
