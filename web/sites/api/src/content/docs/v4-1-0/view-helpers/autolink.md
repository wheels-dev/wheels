---
title: autoLink()
description: "Turns all URLs and email addresses into links."
sidebar:
  label: autoLink()
  order: 0
---

## Signature

`autoLink()` — returns `string`

**Available in:** `controller`
**Category:** Link Functions

## Description

Turns all URLs and email addresses into links.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to create links in. |
| `link` | `string` | no | `all` | Whether to link URLs, email addresses or both. Possible values are: `all` (default), `URLs` and `emailAddresses`. |
| `relative` | `boolean` | no | `true` | Should we auto-link relative urls. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre><code class='javascript'>// 1. Link both URLs and email addresses (default behavior)
result = autoLink(&quot;Download CFWheels from http://cfwheels.org/download&quot;);
// result -&gt; &quot;Download CFWheels from &lt;a href=&quot;http://cfwheels.org/download&quot;&gt;http://cfwheels.org/download&lt;/a&gt;&quot;

// 2. Link email addresses only
result = autoLink(text=&quot;Email us at info@cfwheels.org or visit http://cfwheels.org&quot;, link=&quot;emailAddresses&quot;);
// result -&gt; &quot;Email us at &lt;a href=&quot;mailto:info@cfwheels.org&quot;&gt;info@cfwheels.org&lt;/a&gt; or visit http://cfwheels.org&quot;

// 3. Link URLs only (skip email addresses)
result = autoLink(text=&quot;Visit http://cfwheels.org or contact info@cfwheels.org&quot;, link=&quot;URLs&quot;);
// result -&gt; &quot;Visit &lt;a href=&quot;http://cfwheels.org&quot;&gt;http://cfwheels.org&lt;/a&gt; or contact info@cfwheels.org&quot;

// 4. Disable auto-linking of relative URLs
result = autoLink(text=&quot;See /docs/guide for details or http://cfwheels.org for more.&quot;, relative=false);
// result -&gt; &quot;See /docs/guide for details or &lt;a href=&quot;http://cfwheels.org&quot;&gt;http://cfwheels.org&lt;/a&gt; for more.&quot;
</code></pre>
