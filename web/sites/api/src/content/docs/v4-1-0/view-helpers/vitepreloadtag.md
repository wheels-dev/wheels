---
title: vitePreloadTag()
description: "Returns <code><link rel=\"modulepreload\"></code> tags for a Vite entrypoint and its transitive"
sidebar:
  label: vitePreloadTag()
  order: 0
---

## Signature

`vitePreloadTag()` — returns `string`

**Available in:** `controller`
**Category:** Asset Functions

## Description

Returns <code><link rel="modulepreload"></code> tags for a Vite entrypoint and its transitive
chunk imports. Useful for Turbo Drive hover-preload patterns or for explicitly warming
assets a subsequent navigation will need.
In development mode, returns an empty string — Vite handles module resolution
dynamically and modulepreload is unnecessary.


emits via <code>$viteHtmlHead()</code> so tags land in <code><head></code>.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `entrypoint` | `string` | yes | — | The source entrypoint path (e.g. "src/main.js"). |
| `head` | `boolean` | no | `true` | Set to `false` to return the markup for inline placement; default `true` |

</div>

## Examples

<pre><code class='javascript'>// 1. Emit modulepreload tags into &lt;head&gt; for a JS entrypoint (default behavior)
// In production, injects &lt;link rel=&quot;modulepreload&quot;&gt; for the entrypoint and all
// transitive chunk imports into &lt;head&gt;. Returns an empty string.
// In development, returns an empty string (Vite handles modules dynamically).
vitePreloadTag(&quot;src/main.js&quot;);

// 2. Return modulepreload markup inline instead of injecting into &lt;head&gt;
// Pass head=false to receive the raw HTML for manual placement, for example
// inside a Turbo Drive hover-preload data attribute or a custom &lt;head&gt; partial.
preloadMarkup = vitePreloadTag(entrypoint=&quot;src/main.js&quot;, head=false);
// preloadMarkup -&gt; '&lt;link rel=&quot;modulepreload&quot; href=&quot;/dist/assets/main-Dz8C9a3m.js&quot; /&gt;\n&lt;link rel=&quot;modulepreload&quot; href=&quot;/dist/assets/vendor-BpC2d1a0.js&quot; /&gt;\n'

// 3. Warm assets for a page the user is likely to navigate to next
// Call from a controller action to preload a separate route's entry module
// so the browser fetches chunks before the user clicks the link.
vitePreloadTag(&quot;src/checkout.js&quot;);
</code></pre>
