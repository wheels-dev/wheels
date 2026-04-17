---
title: hiddenFieldTag()
description: "Builds and returns a string containing a hidden field form control based on the supplied name."
sidebar:
  label: hiddenFieldTag()
  order: 0
---

## Signature

`hiddenFieldTag()` — returns `string`

**Available in:** `controller`
**Category:** Form Tag Functions

## Description

Builds and returns a string containing a hidden field form control based on the supplied name.
Note: Pass any additional arguments like <code>class</code>, <code>rel</code>, and <code>id</code>, and the generated tag will also include those values as HTML attributes.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name to populate in tag's name attribute. |
| `value` | `string` | no | — | Value to populate in tag's value attribute. |
| `encode` | `boolean` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>&lt;!--- Basic usage usually involves a `name` and `value` ---&gt;
#hiddenFieldTag(name=&quot;userId&quot;, value=user.id)#</code></pre>
