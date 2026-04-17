---
title: stripTags()
description: "Removes all HTML tags from a string, leaving only the raw text content. Use this when you need to sanitize HTML by completely removing formatting and markup."
sidebar:
  label: stripTags()
  order: 0
---

## Signature

`stripTags()` — returns `string`

**Available in:** `controller`
**Category:** Sanitization Functions

## Description

Removes all HTML tags from a string, leaving only the raw text content. Use this when you need to sanitize HTML by completely removing formatting and markup.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `html` | `string` | yes | — | The HTML to remove tag markup from. |
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |

## Examples

<pre><code class='javascript'>1. Remove all tags from a string
#stripTags('&lt;strong&gt;Wheels&lt;/strong&gt; is a framework for &lt;a href=&quot;http://www.adobe.com/products/coldfusion&quot;&gt;ColdFusion&lt;/a&gt;.')#

Output:
Wheels is a framework for ColdFusion.

2. Sanitize user input
userInput = '&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;Normal text';
#stripTags(userInput)#

Output:
Normal text

3. With encoding
#stripTags('&lt;a href=&quot;http://example.com/page?param=value&amp;another=1&quot;&gt;Example&lt;/a&gt;')#

Output:
Example</code></pre>
