---
title: addFormat()
description: "Adds a new MIME format to your Wheels application for use with responding to multiple formats."
sidebar:
  label: addFormat()
  order: 0
---

## Signature

`addFormat()` — returns `any`




## Description

Adds a new MIME format to your Wheels application for use with responding to multiple formats.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `extension` | `string` | yes | — | File extension to add. |
| `mimeType` | `string` | yes | — | Matching MIME type to associate with the file extension. |

</div>

## Examples

<pre>&lt;!--- Add the `js` format ---&gt;
&lt;cfset addFormat(extension=&quot;js&quot;, mimeType=&quot;text/javascript&quot;)&gt;

&lt;!--- Add the `ppt` and `pptx` formats ---&gt;
&lt;cfset addFormat(extension=&quot;ppt&quot;, mimeType=&quot;application/vnd.ms-powerpoint&quot;)&gt;
&lt;cfset addFormat(extension=&quot;pptx&quot;, mimeType=&quot;application/vnd.ms-powerpoint&quot;)&gt;</pre>
