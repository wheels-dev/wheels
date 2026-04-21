---
title: buttonTag()
description: "Builds and returns a string containing a button form control for use in your HTML forms. Use this helper to create buttons with custom content, types, values, i"
sidebar:
  label: buttonTag()
  order: 0
---

## Signature

`buttonTag()` — returns `string`

**Available in:** `controller`
**Category:** General Form Functions

## Description

Builds and returns a string containing a button form control for use in your HTML forms. Use this helper to create buttons with custom content, types, values, images, and optional HTML wrappers.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `content` | `string` | no | `Save changes` | Content to display inside the button. |
| `type` | `string` | no | `submit` | The type for the button: `button`, `reset`, or `submit`. |
| `value` | `string` | no | `save` | The value of the button when submitted. |
| `image` | `string` | no | — | File name of the image file to use in the button form control. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>1. Basic submit button
#startFormTag(action="something")#
    #buttonTag(content="Submit this form", value="save")#
#endFormTag()#

2. Button with a different type
#buttonTag(content="Reset form", type="reset")#

3. Button using an image
#buttonTag(image="submit.png", value="save")#

4. Button with HTML wrappers
#buttonTag(content="Click Me", prepend="&lt;div class='btn-wrapper'&gt;", append="&lt;/div&gt;")#

5. Disable encoding for raw HTML content
#buttonTag(content="&lt;strong&gt;Submit&lt;/strong&gt;", encode=false)#</code></pre>
