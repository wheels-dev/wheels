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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `html` | `string` | yes | — | The HTML to remove tag markup from. |
| `encode` | `boolean` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre>&lt;!--- Will output: CFWheels is a framework for ColdFusion. ---&gt;
#stripTags('&lt;strong&gt;Wheels&lt;/strong&gt; is a framework for &lt;a href=&quot;http://www.adobe.com/products/coldfusion&quot;&gt;ColdFusion&lt;/a&gt;.')#</pre>
