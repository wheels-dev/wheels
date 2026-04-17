---
title: mimeTypes()
description: "Returns the associated MIME type for a given file extension. Useful when serving files dynamically or setting response headers."
sidebar:
  label: mimeTypes()
  order: 0
---

## Signature

`mimeTypes()` — returns `string`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Returns the associated MIME type for a given file extension. Useful when serving files dynamically or setting response headers.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `extension` | `string` | yes | — | The extension to get the MIME type for. |
| `fallback` | `string` | no | `application/octet-stream` | The fallback MIME type to return. |

## Examples

<pre><code class='javascript'>1. Basic Known Extension
// Get the MIME type for a known extension
mimeType = mimeTypes(&quot;jpg&quot;);
writeOutput(mimeType); // Outputs: &quot;image/jpeg&quot;

2. Unknown Extension With Fallback
// Use a fallback for unknown file types
mimeType = mimeTypes(&quot;abc&quot;, fallback=&quot;text/plain&quot;);
writeOutput(mimeType); // Outputs: &quot;text/plain&quot;

3. Dynamic Extension From User Input
params.type = &quot;pdf&quot;;
mimeType = mimeTypes(extension=params.type);
writeOutput(mimeType); // Outputs: &quot;application/pdf&quot;

4. Serving a File Download
fileName = &quot;report.xlsx&quot;;
fileExt = listLast(fileName, &quot;.&quot;);
cfheader(name=&quot;Content-Disposition&quot;, value=&quot;attachment; filename=#fileName#&quot;);
cfcontent(type=mimeTypes(fileExt), file=&quot;#expandPath('./public/files/' &amp; fileName)#&quot;);</code></pre>
