---
title: submitTag()
description: "Builds and returns a string containing a submit button form control."
sidebar:
  label: submitTag()
  order: 0
---

## Signature

`submitTag()` — returns `string`

**Available in:** `controller`
**Category:** General Form Functions

## Description

Builds and returns a string containing a submit button form control.
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `value` | `string` | no | `Save changes` | Message to display in the button form control. |
| `image` | `string` | no | — | File name of the image file to use in the button form control. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>1. Default submit button
#startFormTag(action=&quot;save&quot;)##submitTag()##endFormTag()#
2. Custom button label
#submitTag(value=&quot;Register Now&quot;)#
3. Submit button with CSS class and ID
#submitTag(value=&quot;Update Profile&quot;, class=&quot;btn btn-primary&quot;, id=&quot;updateBtn&quot;)#
4. Submit as an image button
#submitTag(image=&quot;submit-icon.png&quot;, value=&quot;Submit Form&quot;)#
5. Wrapping with prepend and append
#submitTag(value=&quot;Send Message&quot;, prepend=&quot;&lt;div class='form-actions'&gt;&quot;, append=&quot;&lt;/div&gt;&quot;)#</code></pre>
