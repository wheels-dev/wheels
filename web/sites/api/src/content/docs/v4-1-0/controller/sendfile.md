---
title: sendFile()
description: "Sends a file to the user (from the <code>files</code> folder or a path relative to it by default)."
sidebar:
  label: sendFile()
  order: 0
---

## Signature

`sendFile()` — returns `any`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Sends a file to the user (from the <code>files</code> folder or a path relative to it by default).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `file` | `string` | yes | — | The file to send to the user. Values containing the `..` character sequence anywhere (even as part of a legitimate file name) are rejected to prevent path traversal. |
| `name` | `string` | no | — | The file name to show in the browser download dialog box. |
| `type` | `string` | no | — | The HTTP content type to deliver the file as. |
| `disposition` | `string` | no | `attachment` | Set to `inline` to have the browser handle the opening of the file (possibly inline in the browser) or set to `attachment` to force a download dialog box. |
| `directory` | `string` | no | — | Directory outside of the web root where the file exists. Must be a full path. Values containing the `..` character sequence are rejected to prevent path traversal. |
| `deleteFile` | `boolean` | no | `false` | Pass in `true` to delete the file on the server after sending it. |
| `deliver` | `boolean` | no | `true` | When set to `false`, the file will not be sent to the browser (used for testing). |

</div>

## Examples

<pre><code class='javascript'>// 1. Send a PDF file to the user from the default files folder
sendFile(file=&quot;wheels_tutorial_20081028_J657D6HX.pdf&quot;);

// 2. Send the same file but give the user a friendlier name in the browser download dialog
sendFile(file=&quot;wheels_tutorial_20081028_J657D6HX.pdf&quot;, name=&quot;Tutorial.pdf&quot;);

// 3. Display the file inline in the browser instead of forcing a download dialog
sendFile(file=&quot;report.pdf&quot;, disposition=&quot;inline&quot;);

// 4. Send a file with an explicit MIME type
sendFile(file=&quot;export.csv&quot;, type=&quot;text/csv&quot;, name=&quot;data-export.csv&quot;);

// 5. Send a file located outside of the web root using an absolute directory path
sendFile(file=&quot;invoice_2024_001.pdf&quot;, directory=&quot;/var/app/private/invoices&quot;);

// 6. Send a file and delete it from the server after delivery (e.g., a temporary export)
sendFile(file=&quot;temp_export_J657D6HX.csv&quot;, name=&quot;export.csv&quot;, deleteFile=true);

// 7. Send a file stored in the RAM virtual file system
sendFile(file=&quot;ram://generated_report.pdf&quot;, name=&quot;report.pdf&quot;);
</code></pre>
