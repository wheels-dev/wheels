---
title: stripTags()
description: "Removes all HTML tags from a string."
sidebar:
  label: stripTags()
  order: 0
---

## Signature

`stripTags()` — returns `any`




## Description

Removes all HTML tags from a string.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `html` | `string` | yes | — | The HTML to remove tag markup from. |

</div>

## Examples

<pre>&lt;!--- Outputs &quot;CFWheels is a framework for ColdFusion.&quot; ---&gt;

#stripTags(&quot;&lt;strong&gt;Wheels&lt;/strong&gt; is a framework for &lt;a href=&quot;&quot;http://www.adobe.com/products/coldfusion&quot;&quot;&gt;ColdFusion&lt;/a&gt;.&quot;)#</pre>
