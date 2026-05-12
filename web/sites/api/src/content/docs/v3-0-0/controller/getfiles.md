---
title: getFiles()
description: "The getFiles() function is primarily used in testing scenarios to retrieve information about files sent during the current request. It returns an array containi"
sidebar:
  label: getFiles()
  order: 0
---

## Signature

`getFiles()` — returns `array`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

The getFiles() function is primarily used in testing scenarios to retrieve information about files sent during the current request. It returns an array containing details of all files handled in the request, such as uploaded attachments or generated files. This allows you to inspect and verify file-related operations in automated tests without needing to access the file system directly.




## Examples

<pre><code class='javascript'>1. Get all files sent during the current request
files = getFiles();

// Check if a specific file was sent
for (var file in files) {
    if (file.name EQ &quot;report.pdf&quot;) {
        writeOutput(&quot;File 'report.pdf' was sent.&lt;br&gt;&quot;);
    }
}
</code></pre>
