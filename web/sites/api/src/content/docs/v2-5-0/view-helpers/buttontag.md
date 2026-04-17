---
title: buttonTag()
description: "Builds and returns a string containing a button form control."
sidebar:
  label: buttonTag()
  order: 0
---

## Signature

`buttonTag()` — returns `string`

**Available in:** `controller`
**Category:** General Form Functions

## Description

Builds and returns a string containing a button form control.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `content` | `string` | no | `Save changes` | Content to display inside the button. |
| `type` | `string` | no | `submit` | The type for the button: `button`, `reset`, or `submit`. |
| `value` | `string` | no | `save` | The value of the button when submitted. |
| `image` | `string` | no | — | File name of the image file to use in the button form control. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>&lt;!--- View Code ---&gt;
#startFormTag(action=&quot;something&quot;)#
    &lt;!--- Form Controls go here ---&gt;
    #buttonTag(content=&quot;Submit this form&quot;, value=&quot;save&quot;)#
#endFormTag()#
</code></pre>
