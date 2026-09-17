---
title: viteStyleTag()
description: "Returns a <code><link></code> tag for a Vite CSS entrypoint. In development, Vite injects CSS via"
sidebar:
  label: viteStyleTag()
  order: 0
---

## Signature

`viteStyleTag()` — returns `string`

**Available in:** `controller`
**Category:** Asset Functions

## Description

Returns a <code><link></code> tag for a Vite CSS entrypoint. In development, Vite injects CSS via
the JS client so this returns an empty string. In production, resolves the fingerprinted path.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `entrypoint` | `string` | yes | — | The source CSS entrypoint path (e.g. "src/main.css"). |
| `head` | `boolean` | no | `false` | Set to `true` to place output in the `<head>` area instead of inline. |

</div>

## Examples

<pre><code class='javascript'>// 1. Emit a &lt;link&gt; tag for a standalone CSS entrypoint inline (default)
// In development, returns an empty string — Vite injects CSS via the HMR JS client.
// In production, outputs a fingerprinted &lt;link rel=&quot;stylesheet&quot;&gt; tag.
writeOutput(viteStyleTag(&quot;src/main.css&quot;));

// 2. Place the &lt;link&gt; tag in the &lt;head&gt; instead of inline
// Passes the generated markup to $htmlHead() so it is buffered into the page &lt;head&gt;.
// Returns an empty string; nothing is printed at the call site.
viteStyleTag(entrypoint=&quot;src/main.css&quot;, head=true);

// 3. Emit a &lt;link&gt; tag for a page-specific CSS entrypoint
// Useful when a particular view has its own standalone stylesheet entrypoint
// defined in your Vite config alongside the primary JS bundle.
writeOutput(viteStyleTag(&quot;src/checkout.css&quot;));
</code></pre>
