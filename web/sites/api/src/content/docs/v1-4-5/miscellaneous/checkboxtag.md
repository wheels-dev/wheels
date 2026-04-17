---
title: checkBoxTag()
description: "Builds and returns a string containing a check box form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, and the"
sidebar:
  label: checkBoxTag()
  order: 0
---

## Signature

`checkBoxTag()` — returns `any`




## Description

Builds and returns a string containing a check box form control based on the supplied name. Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | See documentation for textFieldTag. |
| `checked` | `boolean` | yes | `false` | Whether or not the check box should be checked by default. |
| `value` | `string` | yes | `1` | Value of check box in its checked state. |
| `uncheckedValue` | `string` | yes | — | The value of the check box when it's on the unchecked state. |
| `label` | `string` | yes | — | See documentation for textField. |
| `labelPlacement` | `string` | yes | `around` | See documentation for textField. |
| `prepend` | `string` | yes | — | See documentation for textField. |
| `append` | `string` | yes | — | See documentation for textField. |
| `prependToLabel` | `string` | yes | — | See documentation for textField. |
| `appendToLabel` | `string` | yes | — | See documentation for textField. |

## Examples

<pre>&lt;!--- Example 1: Basic usage involves a `label`, `name`, and `value` ---&gt;
&lt;cfoutput&gt;
    #checkBoxTag(name=&quot;subscribe&quot;, value=&quot;true&quot;, label=&quot;Subscribe to our newsletter&quot;, checked=false)#
&lt;/cfoutput&gt;

&lt;!--- Example 2: Loop over a query to display choices and whether or not they are checked ---&gt;
&lt;!--- - Controller code ---&gt;
&lt;cfset pizza = model(&quot;pizza&quot;).findByKey(session.pizzaId)&gt;
&lt;cfset selectedToppings = pizza.toppings()&gt;
&lt;cfset toppings = model(&quot;topping&quot;).findAll(order=&quot;name&quot;)&gt;

&lt;!--- View code ---&gt;
&lt;fieldset&gt;
	&lt;legend&gt;Toppings&lt;/legend&gt;
	&lt;cfoutput query=&quot;toppings&quot;&gt;
		#checkBoxTag(name=&quot;toppings&quot;, value=&quot;true&quot;, label=toppings.name, checked=YesNoFormat(ListFind(ValueList(selectedToppings.id), toppings.id))#
	&lt;/cfoutput&gt;
&lt;/fieldset&gt;</pre>
