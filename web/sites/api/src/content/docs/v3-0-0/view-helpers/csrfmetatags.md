---
title: csrfMetaTags()
description: "The csrfMetaTags() helper generates meta tags containing your application's CSRF authenticity token. This is useful for JavaScript/AJAX requests that need to PO"
sidebar:
  label: csrfMetaTags()
  order: 0
---

## Signature

`csrfMetaTags()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

The csrfMetaTags() helper generates meta tags containing your application's CSRF authenticity token. This is useful for JavaScript/AJAX requests that need to POST data securely, ensuring that the request comes from a trusted source.




## Examples

<pre><code class='javascript'>&lt;head&gt;
    &lt;title&gt;My Application&lt;/title&gt;
    #csrfMetaTags()#
&lt;/head&gt;

// This will output something like:
// &lt;meta name="csrf-token" content="YOUR_AUTH_TOKEN_HERE"&gt;
// &lt;meta name="csrf-param" content="authenticityToken"&gt;</code></pre>
