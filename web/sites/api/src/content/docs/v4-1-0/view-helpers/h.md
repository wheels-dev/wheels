---
title: h()
description: "Encodes a value for safe HTML output. Use in templates to prevent XSS:"
sidebar:
  label: h()
  order: 0
---

## Signature

`h()` — returns `string`

**Available in:** `controller`
**Category:** Sanitization Functions

## Description

Encodes a value for safe HTML output. Use in templates to prevent XSS:
<code>#h(user.name)#</code> instead of <code>#user.name#</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `value` | `any` | yes | — | The value to encode for HTML output. Converted to string if not already. |

</div>

## Examples

<pre><code class='javascript'>// 1. Safely output user-supplied text in a view template
writeOutput(h(user.name));
// If user.name is &quot;&lt;script&gt;alert('xss')&lt;/script&gt;&quot;, outputs the
// HTML-encoded form: &amp;lt;script&amp;gt;alert(&amp;##x27;xss&amp;##x27;)&amp;lt;/script&amp;gt;

// 2. Encode a variable inline in a cfoutput block
//   Instead of: &lt;cfoutput&gt;##user.bio##&lt;/cfoutput&gt;
//   Use:        &lt;cfoutput&gt;##h(user.bio)##&lt;/cfoutput&gt;
encodedBio = h(user.bio);

// 3. Encode a non-string value (converted to string automatically)
rating = 4.5;
writeOutput(h(rating));
// rating -&gt; &quot;4.5&quot;
</code></pre>
