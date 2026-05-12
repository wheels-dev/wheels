---
title: mimeTypes()
description: "Returns an associated MIME type based on a file extension."
sidebar:
  label: mimeTypes()
  order: 0
---

## Signature

`mimeTypes()` — returns `any`




## Description

Returns an associated MIME type based on a file extension.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `extension` | `string` | yes | — | The extension to get the MIME type for. |
| `fallback` | `string` | yes | `application/octet-stream` | The fallback MIME type to return. |

</div>

## Examples

<pre>mimeTypes(extension [, fallback ]) &lt;!--- Get the internally-stored MIME type for `xls` ---&gt;
&lt;cfset mimeType = mimeTypes(&quot;xls&quot;)&gt;

&lt;!--- Get the internally-stored MIME type for a dynamic value. Fall back to a MIME type of `text/plain` if it's not found ---&gt;
&lt;cfset mimeType = mimeTypes(extension=params.type, fallback=&quot;text/plain&quot;)&gt;</pre>
