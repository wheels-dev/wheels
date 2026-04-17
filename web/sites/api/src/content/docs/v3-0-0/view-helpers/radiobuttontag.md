---
title: radioButtonTag()
description: "Generates a standard HTML &lt;input type=\"radio\"&gt; element based on the supplied name and value. Unlike radioButton(), this function works directly with form"
sidebar:
  label: radioButtonTag()
  order: 0
---

## Signature

`radioButtonTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Generates a standard HTML &lt;input type="radio"&gt; element based on the supplied name and value. Unlike radioButton(), this function works directly with form tags rather than binding to a model object. It is useful for simple forms or when you need fine-grained control over the HTML attributes. You can customize the radio button with labels, label placement, HTML wrapping, and encoding to prevent XSS attacks. The generated radio button will be marked as checked if the checked argument is true.



## Parameters

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

## Examples

<pre><code class='javascript'>1. Basic radio buttons for gender
&lt;cfoutput&gt;
&lt;fieldset&gt;
    &lt;legend&gt;Gender&lt;/legend&gt;
    #radioButtonTag(name=&quot;gender&quot;, value=&quot;m&quot;, label=&quot;Male&quot;, checked=true)#&lt;br&gt;
    #radioButtonTag(name=&quot;gender&quot;, value=&quot;f&quot;, label=&quot;Female&quot;)#
&lt;/fieldset&gt;
&lt;/cfoutput&gt;

2. Label before radio button
#radioButtonTag(name=&quot;subscription&quot;, value=&quot;premium&quot;, label=&quot;Premium Plan&quot;, labelPlacement=&quot;before&quot;)#

3. Custom HTML wrappers
#radioButtonTag(
    name=&quot;newsletter&quot;,
    value=&quot;yes&quot;,
    label=&quot;Subscribe&quot;,
    prepend=&quot;&lt;div class='radio-wrapper'&gt;&quot;,
    append=&quot;&lt;/div&gt;&quot;,
    labelPlacement=&quot;aroundRight&quot;
)#
</code></pre>
