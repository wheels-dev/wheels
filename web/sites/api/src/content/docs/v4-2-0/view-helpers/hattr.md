---
title: hAttr()
description: "Encodes a value for safe use inside an HTML attribute."
sidebar:
  label: hAttr()
  order: 0
---

## Signature

`hAttr()` — returns `string`

**Available in:** `controller`
**Category:** Sanitization Functions

## Description

Encodes a value for safe use inside an HTML attribute.
Use when building attribute values manually:
&lt;div title="#hAttr(user.bio)#"&gt;.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `value` | `any` | yes | — | The value to encode for HTML attribute context. |

</div>

## Examples

<pre><code class='javascript'>// 1. Safely encode a user-supplied string inside an HTML attribute
userBio = &quot;Say &quot;&quot;hello&quot;&quot; &amp; &lt;wave&gt;&quot;;
writeOutput('&lt;div title=&quot;#hAttr(userBio)#&quot;&gt;Hover me&lt;/div&gt;');
&lt;!--- Renders: &lt;div title=&quot;Say &amp;#x22;hello&amp;#x22; &amp;amp; &amp;lt;wave&amp;gt;&quot;&gt;Hover me&lt;/div&gt; ---&gt;

// 2. Use directly in a view template to prevent XSS in attribute values
writeOutput('&lt;input type=&quot;text&quot; placeholder=&quot;#hAttr(params.search)#&quot;&gt;');
</code></pre>
