---
title: stripTags()
description: "Removes all HTML tags from a string."
sidebar:
  label: stripTags()
  order: 0
---

## Signature

`stripTags()` — returns `string`

**Available in:** `controller`
**Category:** Sanitization Functions

## Description

Removes all HTML tags from a string.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `html` | `string` | yes | — | The HTML to remove tag markup from. |
| `encode` | `boolean` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>&lt;!--- Will output: CFWheels is a framework for ColdFusion. ---&gt;
#stripTags('&lt;strong&gt;Wheels&lt;/strong&gt; is a framework for &lt;a href=&quot;http://www.adobe.com/products/coldfusion&quot;&gt;ColdFusion&lt;/a&gt;.')#</code></pre>
