---
title: stripLinks()
description: "Removes all links from an HTML string, leaving just the link text."
sidebar:
  label: stripLinks()
  order: 0
---

## Signature

`stripLinks()` — returns `any`




## Description

Removes all links from an HTML string, leaving just the link text.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `html` | `string` | yes | — | The HTML to remove links from. |

</div>

## Examples

<pre>&lt;!--- Outputs &quot;&lt;strong&gt;Wheels&lt;/strong&gt; is a framework for ColdFusion.&quot; ---&gt;

 #stripLinks(&quot;&lt;strong&gt;Wheels&lt;/strong&gt; is a framework for &lt;a href=&quot;&quot;http://www.adobe.com/products/coldfusion&quot;&quot;&gt;ColdFusion&lt;/a&gt;.&quot;)#</pre>
