---
title: addFormat()
description: "Adds a new MIME type to your Wheels application for use with responding to multiple formats."
sidebar:
  label: addFormat()
  order: 0
---

## Signature

`addFormat()` — returns `void`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Adds a new MIME type to your Wheels application for use with responding to multiple formats.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `extension` | `string` | yes | — | File extension to add. |
| `mimeType` | `string` | yes | — | Matching MIME type to associate with the file extension. |

</div>

## Examples

<pre><code class='javascript'>// 1. Add the `js` format
addFormat(extension=&quot;js&quot;, mimeType=&quot;text/javascript&quot;);

// 2. Add the `ppt` and `pptx` formats
addFormat(extension=&quot;ppt&quot;, mimeType=&quot;application/vnd.ms-powerpoint&quot;);
addFormat(extension=&quot;pptx&quot;, mimeType=&quot;application/vnd.ms-powerpoint&quot;);

// 3. Add a custom `csv` format so controllers can respond with `responds(formats=&quot;csv&quot;)`
addFormat(extension=&quot;csv&quot;, mimeType=&quot;text/csv&quot;);
</code></pre>
