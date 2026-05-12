---
title: simpleFormat()
description: "Returns formatted text using HTML break tags (<code><br></code>) and HTML paragraph elements (<code><p></p></code>) based on the newline characters and carriage"
sidebar:
  label: simpleFormat()
  order: 0
---

## Signature

`simpleFormat()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Returns formatted text using HTML break tags (<code><br></code>) and HTML paragraph elements (<code><p></p></code>) based on the newline characters and carriage returns in the <code>text</code> that is passed in.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to format. |
| `wrap` | `boolean` | no | `true` | Set to `true` to wrap the result in a paragraph HTML element. |
| `encode` | `boolean` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>&lt;!--- How most of your calls will look. ---&gt;
#simpleFormat(post.bodyText)#

&lt;!--- Demonstrates what output looks like with specific data. ---&gt;
&lt;cfsavecontent variable=&quot;comment&quot;&gt;
	I love this post!

	Here's why:
	* Short
	* Succinct
	* Awesome
&lt;/cfsavecontent&gt;
#simpleFormat(comment)#

&lt;!---
	&lt;p&gt;I love this post!&lt;/p&gt;

	&lt;p&gt;Here's why:&lt;br&gt;
	* Short&lt;br&gt;
	* Succinct&lt;br&gt;
	* Awesome&lt;/p&gt;
---&gt;</code></pre>
