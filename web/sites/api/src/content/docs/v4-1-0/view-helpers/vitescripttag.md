---
title: viteScriptTag()
description: "Returns 'script' tags for a Vite JS entrypoint. In development, also injects the Vite"
sidebar:
  label: viteScriptTag()
  order: 0
---

## Signature

`viteScriptTag()` — returns `string`

**Available in:** `controller`
**Category:** Asset Functions

## Description

Returns 'script' tags for a Vite JS entrypoint. In development, also injects the Vite
client for Hot Module Replacement (HMR). In production, includes any associated CSS files
from the manifest as <code><link></code> tags.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `entrypoint` | `string` | yes | — | The source entrypoint path (e.g. "src/main.js"). |
| `head` | `boolean` | no | `false` | Set to `true` to place output in the `<head>` area instead of inline. |

</div>

## Examples

<pre><code class='javascript'>// 1. Emit a script tag for a Vite JS entrypoint inline (default)
// In development, also injects the Vite HMR client.
// In production, emits &lt;link&gt; tags for any associated CSS and a &lt;script type=&quot;module&quot;&gt; tag.
writeOutput(viteScriptTag(&quot;src/main.js&quot;));

// 2. Place the script tag in the &lt;head&gt; instead of inline
// Passes the generated markup to $htmlHead() so it is buffered into the page &lt;head&gt;.
// Returns an empty string; nothing is printed at the call site.
viteScriptTag(entrypoint=&quot;src/main.js&quot;, head=true);

// 3. Emit a script tag for a page-specific entrypoint
// Each entrypoint gets its own script tag; CSS chunks discovered in the
// manifest are automatically included as &lt;link rel=&quot;stylesheet&quot;&gt; tags.
writeOutput(viteScriptTag(&quot;src/checkout.js&quot;));
</code></pre>
