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
| `encode` | `any` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre>&lt;!--- View Code ---&gt;
#startFormTag(action=&quot;something&quot;)#
    &lt;!--- Form Controls go here ---&gt;
    #buttonTag(content=&quot;Submit this form&quot;, value=&quot;save&quot;)#
#endFormTag()#
</pre>
