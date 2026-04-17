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

<pre><code class='javascript'>&lt;!--- Needed here because we're not using `startFormTag`. ---&gt;
&lt;form action=&quot;#urlFor(route='posts')#&quot; method=&quot;post&quot;&gt;
  #authenticityTokenField()#
&lt;/form&gt;
  
&lt;!--- Not needed here because we're not POSTing the form. ---&gt;
&lt;form action=&quot;#urlFor(route='invoices')#&quot; method=&quot;get&quot;&gt;
&lt;/form&gt;</code></pre>
