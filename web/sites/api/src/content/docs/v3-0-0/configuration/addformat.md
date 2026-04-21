---
title: addFormat()
description: "Registers a new MIME type in your Wheels application for use with responding to multiple formats. This is helpful when your app needs to handle file types beyon"
sidebar:
  label: addFormat()
  order: 0
---

## Signature

`addFormat()` — returns `void`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Miscellaneous Functions

## Description

Registers a new MIME type in your Wheels application for use with responding to multiple formats. This is helpful when your app needs to handle file types beyond the defaults provided by Wheels (e.g., serving JavaScript, PowerPoint, JSON, custom data formats).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `extension` | `string` | yes | — | File extension to add. |
| `mimeType` | `string` | yes | — | Matching MIME type to associate with the file extension. |

</div>

## Examples

<pre><code class='javascript'>1. Add a JavaScript format
addFormat(
    extension=&quot;js&quot;,
    mimeType=&quot;text/javascript&quot;
);

Allows controllers to respond to .js requests with the correct MIME type.

2. Add PowerPoint formats
addFormat(extension=&quot;ppt&quot;, mimeType=&quot;application/vnd.ms-powerpoint&quot;);
addFormat(extension=&quot;pptx&quot;, mimeType=&quot;application/vnd.ms-powerpoint&quot;);

Enables Wheels to correctly serve legacy and modern PowerPoint files.

3. Add JSON format
addFormat(
    extension=&quot;json&quot;,
    mimeType=&quot;application/json&quot;
);

Useful for APIs that need to respond with .json requests.

4. Add PDF format
addFormat(
    extension=&quot;pdf&quot;,
    mimeType=&quot;application/pdf&quot;
);

Ensures .pdf responses are correctly labeled for browsers.

5. Add multiple custom data formats
addFormat(extension=&quot;csv&quot;, mimeType=&quot;text/csv&quot;);
addFormat(extension=&quot;yaml&quot;, mimeType=&quot;application/x-yaml&quot;);

Expands your app to handle CSV and YAML outputs.</code></pre>
