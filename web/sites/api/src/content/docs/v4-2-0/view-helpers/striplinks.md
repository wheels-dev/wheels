---
title: stripLinks()
description: "Removes all links from an HTML string, leaving just the link text."
sidebar:
  label: stripLinks()
  order: 0
---

## Signature

`stripLinks()` — returns `string`

**Available in:** `controller`
**Category:** Sanitization Functions

## Description

Removes all links from an HTML string, leaving just the link text.


Defaults to <code>false</code> (configurable per-function via
<code>set(functionName="stripLinks", encode=true)</code>). These helpers strip
markup; they are NOT an escaping strategy — when the goal is XSS-safe
output, use <code>h()</code> / <code>hAttr()</code> instead.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `html` | `string` | yes | — | The HTML to remove links from. |
| `encode` | `boolean` | no | `true` | Whether to HTML-encode the remaining text after stripping. |

</div>

## Examples

<pre><code class='javascript'>// 1. Remove a link from an HTML string, leaving only the link text
result = stripLinks('&lt;strong&gt;Wheels&lt;/strong&gt; is a framework for &lt;a href=&quot;http://www.adobe.com/products/coldfusion&quot;&gt;ColdFusion&lt;/a&gt;.');
// result -&gt; &quot;&lt;strong&gt;Wheels&lt;/strong&gt; is a framework for ColdFusion.&quot;

// 2. Strip multiple links from a string
result = stripLinks('Visit &lt;a href=&quot;https://cfwheels.org&quot;&gt;CFWheels&lt;/a&gt; or read the &lt;a href=&quot;https://cfwheels.org/docs&quot;&gt;docs&lt;/a&gt; for more info.');
// result -&gt; &quot;Visit CFWheels or read the docs for more info.&quot;

// 3. Strip links while skipping XSS encoding (e.g. when you trust the source HTML)
result = stripLinks('&lt;p&gt;Check out &lt;a href=&quot;https://cfwheels.org&quot;&gt;CFWheels&lt;/a&gt;!&lt;/p&gt;', encode=false);
// result -&gt; &quot;&lt;p&gt;Check out CFWheels!&lt;/p&gt;&quot;
</code></pre>
