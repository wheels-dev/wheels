---
title: endFormTag()
description: "Builds and returns a string containing the closing <code>form</code> tag."
sidebar:
  label: endFormTag()
  order: 0
---

## Signature

`endFormTag()` — returns `string`

**Available in:** `controller`
**Category:** General Form Functions

## Description

Builds and returns a string containing the closing <code>form</code> tag.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `prepend` | `string` | no | — | String to prepend to the form control. Useful to wrap the form control with HTML tags. |
| `append` | `string` | no | — | String to append to the form control. Useful to wrap the form control with HTML tags. |
| `encode` | `any` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre>&lt;!--- view code ---&gt;
#startFormTag(action=&quot;create&quot;)#
   &lt;!---  your form controls ---&gt;
#endFormTag()#
</pre>
