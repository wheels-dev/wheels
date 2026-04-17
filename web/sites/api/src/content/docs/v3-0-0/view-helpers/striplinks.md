---
title: stripLinks()
description: "Removes all &lt;a&gt; tags (hyperlinks) from an HTML string while preserving the inner text. This is useful when you want to display content without clickable l"
sidebar:
  label: stripLinks()
  order: 0
---

## Signature

`stripLinks()` — returns `string`

**Available in:** `controller`
**Category:** Sanitization Functions

## Description

Removes all &lt;a&gt; tags (hyperlinks) from an HTML string while preserving the inner text. This is useful when you want to display content without clickable links but still retain the text inside them.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `html` | `string` | yes | — | The HTML to remove links from. |
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |

## Examples

<pre><code class='javascript'>1. Remove links but keep text
#stripLinks('&lt;strong&gt;Wheels&lt;/strong&gt; is a framework for &lt;a href=&quot;http://www.adobe.com/products/coldfusion&quot;&gt;ColdFusion&lt;/a&gt;.')#

Output:
&lt;strong&gt;Wheels&lt;/strong&gt; is a framework for ColdFusion.

2. Strip links from user-submitted content
userComment = '&lt;p&gt;Check out &lt;a href=&quot;http://spam.com&quot;&gt;this link&lt;/a&gt;!&lt;/p&gt;';
#stripLinks(userComment)#

Output:
&lt;p&gt;Check out this link!&lt;/p&gt;

3. Encoding URLs (optional)
#stripLinks('&lt;a href=&quot;http://example.com/page?param=value&amp;another=1&quot;&gt;Example&lt;/a&gt;', encode=false)#

Output:
Example</code></pre>
