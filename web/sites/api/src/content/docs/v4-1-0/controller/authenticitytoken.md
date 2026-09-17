---
title: authenticityToken()
description: "Returns the raw CSRF authenticity token"
sidebar:
  label: authenticityToken()
  order: 0
---

## Signature

`authenticityToken()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Returns the raw CSRF authenticity token




## Examples

<pre><code class='javascript'>// 1. Embed the CSRF token in a manually-built form hidden field
token = authenticityToken();
writeOutput('&lt;input type=&quot;hidden&quot; name=&quot;authenticityToken&quot; value=&quot;' &amp; token &amp; '&quot;&gt;');

// 2. Pass the token as a request header for an AJAX call (e.g. in a JavaScript data island)
writeOutput('&lt;meta name=&quot;csrf-token&quot; content=&quot;' &amp; authenticityToken() &amp; '&quot;&gt;');
// JavaScript can then read this and send it as the X-CSRF-Token header with each POST request.

// 3. Include the token in a JSON API response body so a client can replay it
tokenValue = authenticityToken();
writeOutput(serializeJSON({authenticityToken = tokenValue}));
</code></pre>
