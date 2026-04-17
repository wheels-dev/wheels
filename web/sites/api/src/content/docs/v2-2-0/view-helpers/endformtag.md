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
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>&lt;!--- view code ---&gt;
#startFormTag(action=&quot;create&quot;)#
   &lt;!---  your form controls ---&gt;
#endFormTag()#
</code></pre>
