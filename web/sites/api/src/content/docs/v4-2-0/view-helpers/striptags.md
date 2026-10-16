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


Defaults to <code>false</code> (configurable per-function via
<code>set(functionName="stripTags", encode=true)</code>). These helpers strip
markup; they are NOT an escaping strategy — when the goal is XSS-safe
output, use <code>h()</code> / <code>hAttr()</code> instead.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `html` | `string` | yes | — | The HTML to remove tag markup from. |
| `encode` | `boolean` | no | `true` | Whether to HTML-encode the remaining text after stripping. |

</div>

## Examples

<pre><code class='javascript'>// 1. Strip all HTML tags from a string, leaving plain text
result = stripTags('&lt;strong&gt;CFWheels&lt;/strong&gt; is a framework for &lt;a href=&quot;http://www.adobe.com/products/coldfusion&quot;&gt;ColdFusion&lt;/a&gt;.');
// result -&gt; &quot;CFWheels is a framework for ColdFusion.&quot;

// 2. Strip tags from a richer HTML fragment
result = stripTags('&lt;h1&gt;Welcome&lt;/h1&gt;&lt;p&gt;This is a &lt;em&gt;great&lt;/em&gt; framework.&lt;/p&gt;');
// result -&gt; &quot;WelcomeThis is a great framework.&quot;

// 3. Strip tags while skipping XSS encoding (e.g. when you trust the source HTML)
result = stripTags('&lt;p&gt;Hello, &lt;strong&gt;world&lt;/strong&gt;!&lt;/p&gt;', encode=false);
// result -&gt; &quot;Hello, world!&quot;
</code></pre>
