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

<pre><code class='javascript'>// 1. Format a blog post body — newlines become &lt;br&gt; and blank lines become paragraph breaks
writeOutput(simpleFormat(post.bodyText));
// A single newline becomes &lt;br&gt;
// A blank line (two newlines) becomes &lt;/p&gt;&lt;p&gt;
// The result is wrapped in &lt;p&gt;...&lt;/p&gt; by default

// 2. Demonstrate the HTML output with literal input
text = &quot;I love this post!&quot; &amp; Chr(10) &amp; Chr(10) &amp; &quot;Here's why:&quot; &amp; Chr(10) &amp; &quot;* Short&quot; &amp; Chr(10) &amp; &quot;* Succinct&quot;;
writeOutput(simpleFormat(text));
// -&gt; &lt;p&gt;I love this post!&lt;/p&gt;
//
//    &lt;p&gt;Here's why:&lt;br&gt;
//    * Short&lt;br&gt;
//    * Succinct&lt;/p&gt;

// 3. Skip the wrapping paragraph tag (wrap=false) when you are composing markup yourself
writeOutput(&quot;&lt;div&gt;&quot; &amp; simpleFormat(text=post.excerpt, wrap=false) &amp; &quot;&lt;/div&gt;&quot;);

// 4. Disable XSS encoding when the text is already trusted/pre-encoded HTML
writeOutput(simpleFormat(text=post.bodyText, encode=false));
</code></pre>
