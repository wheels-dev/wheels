---
title: textFieldTag()
description: "Builds and returns a string containing a text field form control based on the supplied name."
sidebar:
  label: textFieldTag()
  order: 0
---

## Signature

`textFieldTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing a text field form control based on the supplied name.
Note: Pass any additional arguments like <code>class</code>, <code>rel</code>, and <code>id</code>, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `value` | `string` | no | — | Value to populate in tag's value attribute. |
| `label` | `string` | no | — | The label text to use in the form control. |
| `labelPlacement` | `string` | no | `around` | Whether to place the label before, after, or wrapped around the form control. Label text placement can be controlled using aroundLeft or aroundRight. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `prependToLabel` | `string` | no | — | String to prepend to the form control's label. Useful to wrap the form control with HTML tags. |
| `appendToLabel` | `string` | no | — | String to append to the form control's label. Useful to wrap the form control with HTML tags. |
| `type` | `string` | no | `text` | Input type attribute. Common examples in HTML5 and later are text (default), email, tel, and url. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>// 1. Basic search field with a label and a pre-filled value from params
#textFieldTag(name=&quot;q&quot;, label=&quot;Search&quot;, value=params.q)#

// 2. Email input using the HTML5 type attribute
#textFieldTag(name=&quot;email&quot;, label=&quot;Email address&quot;, type=&quot;email&quot;, value=params.email)#

// 3. Field with label placed before the input and extra HTML attributes
#textFieldTag(name=&quot;username&quot;, label=&quot;Username&quot;, labelPlacement=&quot;before&quot;, class=&quot;form-control&quot;, placeholder=&quot;Enter username&quot;)#

// 4. Wrapping the input with Bootstrap input-group markup using prepend and append
#textFieldTag(name=&quot;website&quot;, label=&quot;Website&quot;, type=&quot;url&quot;, prepend=&quot;&lt;div class=&quot;&quot;input-group&quot;&quot;&gt;&quot;, append=&quot;&lt;/div&gt;&quot;)#
</code></pre>
