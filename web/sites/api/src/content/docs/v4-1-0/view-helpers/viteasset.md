---
title: viteAsset()
description: "Returns the resolved URL for a Vite entrypoint. In production, reads the Vite manifest"
sidebar:
  label: viteAsset()
  order: 0
---

## Signature

`viteAsset()` — returns `string`

**Available in:** `controller`
**Category:** Asset Functions

## Description

Returns the resolved URL for a Vite entrypoint. In production, reads the Vite manifest
to return the fingerprinted asset path. In development, returns the Vite dev server URL.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `entrypoint` | `string` | yes | — | The source entrypoint path as defined in your Vite config (e.g. "src/main.js"). |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the resolved URL for a Vite JS entrypoint
// In production, returns a fingerprinted path like &quot;/dist/assets/main-Dz8C9a3m.js&quot;
// In development, returns the Vite dev server URL like &quot;http://localhost:5173/src/main.js&quot;
assetUrl = viteAsset(&quot;src/main.js&quot;);

// 2. Use the resolved URL directly in an image or font tag
logoUrl = viteAsset(&quot;src/images/logo.png&quot;);
writeOutput('&lt;img src=&quot;#logoUrl#&quot; alt=&quot;Logo&quot;&gt;');

// 3. Resolve a CSS entrypoint URL for manual use (e.g. a preload hint)
cssUrl = viteAsset(&quot;src/main.css&quot;);
writeOutput('&lt;link rel=&quot;preload&quot; as=&quot;style&quot; href=&quot;#cssUrl#&quot;&gt;');
</code></pre>
