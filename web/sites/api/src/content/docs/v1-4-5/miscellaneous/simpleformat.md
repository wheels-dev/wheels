---
title: simpleFormat()
description: "Replaces single newline characters with HTML break tags and double newline characters with HTML paragraph tags (properly closed to comply with XHTML standards)."
sidebar:
  label: simpleFormat()
  order: 0
---

## Signature

`simpleFormat()` — returns `any`




## Description

Replaces single newline characters with HTML break tags and double newline characters with HTML paragraph tags (properly closed to comply with XHTML standards).

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to format. |
| `wrap` | `boolean` | yes | `true` | Set to true to wrap the result in a paragraph. |

</div>

## Examples

<pre>&lt;!--- How most of your calls will look ---&gt;
#simpleFormat(post.bodyText)#

&lt;!--- Demonstrates what output looks like with specific data ---&gt;
&lt;cfsavecontent variable=&quot;comment&quot;&gt;
	I love this post!

	Here''s why:
	* Short
	* Succinct
	* Awesome
&lt;/cfsavecontent&gt;
#simpleFormat(comment)#
-&gt; &lt;p&gt;I love this post!&lt;/p&gt;
   &lt;p&gt;
       Here''s why:&lt;br /&gt;
	   * Short&lt;br /&gt;
	   * Succinct&lt;br /&gt;
	   * Awesome
   &lt;/p&gt;</pre>
