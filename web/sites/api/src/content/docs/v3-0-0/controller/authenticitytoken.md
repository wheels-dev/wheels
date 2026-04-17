---
title: authenticityToken()
description: "Returns the raw CSRF authenticity token for the current user session. This token is used to help protect against Cross-Site Request Forgery (CSRF) attacks by ve"
sidebar:
  label: authenticityToken()
  order: 0
---

## Signature

`authenticityToken()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Returns the raw CSRF authenticity token for the current user session. This token is used to help protect against Cross-Site Request Forgery (CSRF) attacks by verifying that form submissions or AJAX requests originate from your application. You typically won’t call this function directly in views — instead, Wheels provides helpers like authenticityTokenField() to generate hidden form fields. But authenticityToken() can be useful if you need direct access to the token string (for example, in custom JavaScript code).




## Examples

<pre><code class='javascript'>1. Get the raw CSRF token in a controller
token = authenticityToken();

2. Output token manually in a form (not recommended, but possible)
&lt;form action="/posts/create" method="post"&gt;
    &lt;input type="hidden" name="authenticityToken" value="#authenticityToken()#"&gt;
    &lt;input type="text" name="title"&gt;
    &lt;input type="submit" value="Save"&gt;
&lt;/form&gt;

3. Use in AJAX request headers
fetch("/posts/create", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "X-CSRF-Token": "<cfoutput>#authenticityToken()#</cfoutput>"
  },
  body: JSON.stringify({ title: "New Post" })
});</code></pre>
