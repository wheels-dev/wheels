---
title: mimeTypes()
description: "Returns an associated MIME type based on a file extension."
sidebar:
  label: mimeTypes()
  order: 0
---

## Signature

`mimeTypes()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Returns an associated MIME type based on a file extension.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `extension` | `string` | yes | — | The extension to get the MIME type for. |
| `fallback` | `string` | no | `application/octet-stream` | The fallback MIME type to return. |

</div>

## Examples

<pre><code class='javascript'>// 1. Get the MIME type for a known file extension
mimeType = mimeTypes(&quot;xls&quot;);
// mimeType -&gt; &quot;application/vnd.ms-excel&quot;

// 2. Get the MIME type for a dynamic extension from user input, with a custom fallback
mimeType = mimeTypes(extension=params.fileType, fallback=&quot;text/plain&quot;);

// 3. Use the default fallback (application/octet-stream) for an unknown extension
mimeType = mimeTypes(&quot;xyz&quot;);
// mimeType -&gt; &quot;application/octet-stream&quot;
</code></pre>
