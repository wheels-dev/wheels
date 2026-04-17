---
title: simpleFormat()
description: "Takes plain text and converts newline and carriage return characters into HTML <code>&lt;br&gt;</code> and <code>&lt;p&gt;</code> tags for display in a browser."
sidebar:
  label: simpleFormat()
  order: 0
---

## Signature

`simpleFormat()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Takes plain text and converts newline and carriage return characters into HTML <code>&lt;br&gt;</code> and <code>&lt;p&gt;</code> tags for display in a browser. This is particularly useful for rendering user-submitted text (like blog posts, comments, or descriptions) in a way that respects the author’s formatting. By default, the text is wrapped in a <code>&lt;p&gt;</code> element and URL parameters are encoded for safety.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to format. |
| `wrap` | `boolean` | no | `true` | Set to `true` to wrap the result in a paragraph HTML element. |
| `encode` | `boolean` | no | `true` | Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead. |

## Examples

<pre><code class='javascript'>1. Typical usage
#simpleFormat(post.bodyText)#

If post.bodyText =
This is the first line.

This is the second paragraph.

Output:

&lt;p&gt;This is the first line.&lt;/p&gt;
&lt;p&gt;This is the second paragraph.&lt;/p&gt;

2. Demonstrating line breaks
&lt;cfsavecontent variable=&quot;comment&quot;&gt;
I love this post!

Here's why:
* Short
* Succinct
* Awesome
&lt;/cfsavecontent&gt;

#simpleFormat(comment)#

Output:

&lt;p&gt;I love this post!&lt;/p&gt;
&lt;p&gt;Here's why:&lt;br&gt;
* Short&lt;br&gt;
* Succinct&lt;br&gt;
* Awesome&lt;/p&gt;

3. Disable paragraph wrapping
&lt;cfsavecontent variable=&quot;bio&quot;&gt;
Hello, I’m Salman.
I write about ColdFusion and backend development.
&lt;/cfsavecontent&gt;

#simpleFormat(bio, wrap=false)#

Output:

Hello, I’m Salman.&lt;br&gt;
I write about ColdFusion and backend development.

//No &lt;p&gt; tags, only &lt;br&gt; for newlines.

4. Handling user input safely
When you’re rendering user-submitted text in HTML attributes, simpleFormat() alone is not enough:

&lt;!-- Incorrect usage in an attribute --&gt;
&lt;div title=&quot;#simpleFormat(userInput)#&quot;&gt;...&lt;/div&gt;

Instead, combine with EncodeForHtmlAttribute():

&lt;div title=&quot;#EncodeForHtmlAttribute(simpleFormat(userInput))#&quot;&gt;...&lt;/div&gt;</code></pre>
