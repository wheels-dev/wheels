---
title: toXHTML()
description: "Returns an XHTML-compliant string."
sidebar:
  label: toXHTML()
  order: 0
---

## Signature

`toXHTML()` — returns `any`




## Description

Returns an XHTML-compliant string.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | String to make XHTML-compliant. |

## Examples

<pre>toXHTML(text) &lt;!--- Outputs `productId=5&amp;amp;categoryId=12&amp;amp;returningCustomer=1` ---&gt;
&lt;cfoutput&gt;
    #toXHTML(&quot;productId=5&amp;categoryId=12&amp;returningCustomer=1&quot;)#
&lt;/cfoutput&gt;</pre>
