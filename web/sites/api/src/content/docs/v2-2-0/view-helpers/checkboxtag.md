---
title: checkBoxTag()
description: "Builds and returns a string containing a check box form control based on the supplied name."
sidebar:
  label: checkBoxTag()
  order: 0
---

## Signature

`checkBoxTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing a check box form control based on the supplied name.
Note: Pass any additional arguments like <code>class</code>, <code>rel</code>, and <code>id</code>, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `checked` | `boolean` | no | `false` | Whether or not the check box should be checked by default. |
| `value` | `string` | no | `1` | Value of check box in its checked state. |
| `uncheckedValue` | `string` | no | — | The value of the check box when it's on the unchecked state. |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>&lt;!--- Example 1: Basic usage involves a `label`, `name`, and `value` ---&gt;
#checkBoxTag(name=&quot;subscribe&quot;, value=&quot;true&quot;, label=&quot;Subscribe to our newsletter&quot;, checked=false)#

&lt;!--- Example 2: Loop over a query to display choices and whether or not they are checked ---&gt;
// Controller code
pizza = model(&quot;pizza&quot;).findByKey(session.pizzaId);
selectedToppings = pizza.toppings();
toppings = model(&quot;topping&quot;).findAll(order=&quot;name&quot;);

&lt;!--- View code ---&gt;
&lt;fieldset&gt;
	&lt;legend&gt;Toppings&lt;/legend&gt;
	&lt;cfoutput query=&quot;toppings&quot;&gt;
		#checkBoxTag(name=&quot;toppings&quot;, value=&quot;true&quot;, label=toppings.name, checked=YesNoFormat(ListFind(ValueList(selectedToppings.id), toppings.id))#
	&lt;/cfoutput&gt;
&lt;/fieldset&gt;</code></pre>
