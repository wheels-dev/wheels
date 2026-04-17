---
title: authenticityTokenField()
description: "Generates a hidden form field that contains a CSRF authenticity token. This token is required for verifying that POST, PUT, PATCH, or DELETE requests originated"
sidebar:
  label: authenticityTokenField()
  order: 0
---

## Signature

`authenticityTokenField()` — returns `string`

**Available in:** `controller`
**Category:** General Form Functions

## Description

Generates a hidden form field that contains a CSRF authenticity token. This token is required for verifying that POST, PUT, PATCH, or DELETE requests originated from your application, helping protect against Cross-Site Request Forgery (CSRF) attacks. When you use startFormTag(), Wheels automatically includes the token field for you. You’ll usually only need to call authenticityTokenField() manually when creating forms without startFormTag() or when building raw HTML forms.




## Examples

<pre><code class='javascript'>1. Adding a CSRF token to a manual form
&lt;!--- Needed here because we're not using startFormTag ---&gt;
&lt;form action="#urlFor(route='posts')#" method="post"&gt;
  #authenticityTokenField()#
  &lt;input type="text" name="title"&gt;
  &lt;input type="submit" value="Create Post"&gt;
&lt;/form&gt;

2. No token needed for safe GET forms
&lt;!--- Not needed here because GET requests are not protected ---&gt;
&lt;form action="#urlFor(route='invoices')#" method="get"&gt;
  &lt;input type="text" name="search"&gt;
  &lt;input type="submit" value="Find Invoice"&gt;
&lt;/form&gt;

3. Custom AJAX form with CSRF token
&lt;form id="ajaxForm"&gt;
  #authenticityTokenField()#
  &lt;input type="text" name="title"&gt;
  &lt;button type="submit"&gt;Save&lt;/button&gt;
&lt;/form&gt;

document.getElementById("ajaxForm").addEventListener("submit", function(e) {
  e.preventDefault();

  const token = document.querySelector("input[name='authenticityToken']").value;

  fetch("/posts", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": token
    },
    body: JSON.stringify({ title: "CSRF-protected post" })
  });
});</code></pre>
