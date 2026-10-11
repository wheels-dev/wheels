---
title: getFiles()
description: "Primarily used for testing to get information about files sent during the request."
sidebar:
  label: getFiles()
  order: 0
---

## Signature

`getFiles()` — returns `array`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Primarily used for testing to get information about files sent during the request.




## Examples

<pre><code class='javascript'>// 1. Assert that exactly one file was sent during the action (in a test)
processDownload();
files = getFiles();
assert(&quot;arrayLen(files) eq 1&quot;);
assert(&quot;files[1].name eq 'report.pdf'&quot;);

// 2. Inspect all files sent during a request
files = getFiles();
for (file in files) {
	writeOutput(file.name &amp; &quot; — &quot; &amp; file.type);
}

// 3. Return an empty array when no files were sent
files = getFiles();
// files -&gt; []
</code></pre>
