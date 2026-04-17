---
title: sendFile()
description: "Sends a file to the client. By default, it serves files from the <code>public/files</code> folder in your project or a path relative to it. You can control how"
sidebar:
  label: sendFile()
  order: 0
---

## Signature

`sendFile()` — returns `any`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Sends a file to the client. By default, it serves files from the <code>public/files</code> folder in your project or a path relative to it. You can control how the file is presented to the user (download dialog vs inline display), set the content type, rename it for the client, or even delete it from the server after delivery.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `file` | `string` | yes | — | The file to send to the user. |
| `name` | `string` | no | — | The file name to show in the browser download dialog box. |
| `type` | `string` | no | — | The HTTP content type to deliver the file as. |
| `disposition` | `string` | no | `attachment` | Set to `inline` to have the browser handle the opening of the file (possibly inline in the browser) or set to `attachment` to force a download dialog box. |
| `directory` | `string` | no | — | Directory outside of the web root where the file exists. Must be a full path. |
| `deleteFile` | `boolean` | no | `false` | Pass in `true` to delete the file on the server after sending it. |
| `deliver` | `boolean` | no | `true` |  |

## Examples

<pre><code class='javascript'>1. Send a file for download from the files folder
sendFile(file=&quot;wheels_tutorial_20081028_J657D6HX.pdf&quot;);

2. Rename the file for the client
sendFile(
    file=&quot;wheels_tutorial_20081028_J657D6HX.pdf&quot;,
    name=&quot;Tutorial.pdf&quot;
);

3. Send a file located outside the web root
sendFile(
    file=&quot;../../tutorials/wheels_tutorial_20081028_J657D6HX.pdf&quot;
);

4. Inline display instead of download
sendFile(
    file=&quot;brochure.pdf&quot;,
    disposition=&quot;inline&quot;,
    type=&quot;application/pdf&quot;
);

5. Delete file after sending
sendFile(
    file=&quot;temporary_report.xlsx&quot;,
    deleteFile=true
);</code></pre>
