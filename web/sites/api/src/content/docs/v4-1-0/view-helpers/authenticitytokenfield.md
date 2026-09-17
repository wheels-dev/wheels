---
title: authenticityTokenField()
description: "Returns a hidden form field containing a new authenticity token."
sidebar:
  label: authenticityTokenField()
  order: 0
---

## Signature

`authenticityTokenField()` — returns `string`

**Available in:** `controller`
**Category:** General Form Functions

## Description

Returns a hidden form field containing a new authenticity token.




## Examples

<pre><code class='javascript'>// 1. Include CSRF token in a plain HTML form that POSTs data
//    (use this when you are not using startFormTag())
&lt;form action=&quot;#urlFor(route='posts')#&quot; method=&quot;post&quot;&gt;
  #authenticityTokenField()#
  &lt;!--- other fields here ---&gt;
&lt;/form&gt;

// 2. Not needed for GET forms — GET requests are not CSRF-protected
&lt;form action=&quot;#urlFor(route='posts')#&quot; method=&quot;get&quot;&gt;
  &lt;!--- no token required ---&gt;
&lt;/form&gt;
</code></pre>
