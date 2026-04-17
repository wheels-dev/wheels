---
title: mimeTypes()
description: "Returns an associated MIME type based on a file extension."
sidebar:
  label: mimeTypes()
  order: 0
---

## Signature

`mimeTypes()` — returns `string`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Returns an associated MIME type based on a file extension.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `extension` | `string` | yes | — | The extension to get the MIME type for. |
| `fallback` | `string` | no | `application/octet-stream` | The fallback MIME type to return. |

## Examples

<pre><code class='javascript'>// Get the internally-stored MIME type for `xls`
mimeType = mimeTypes(&quot;xls&quot;);

// Get the internally-stored MIME type for a dynamic value. Fall back to a MIME type of `text/plain` if it's not found
mimeType = mimeTypes(extension=params.type, fallback=&quot;text/plain&quot;);</code></pre>
