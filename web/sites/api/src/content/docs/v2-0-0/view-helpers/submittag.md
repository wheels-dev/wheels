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

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `value` | `string` | no | `Save changes` | Message to display in the button form control. |
| `image` | `string` | no | — | File name of the image file to use in the button form control. |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre>#startFormTag(action=&quot;something&quot;)#
    &lt;!--- form controls go here ---&gt;
    #submitTag()#
#endFormTag()#
</pre>
