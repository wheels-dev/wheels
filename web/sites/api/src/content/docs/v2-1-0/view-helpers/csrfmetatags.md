---
title: csrfMetaTags()
description: "Include this in your layouts' <code>head</code> sections to include meta tags containing the authenticity token for use by JavaScript AJAX requests needing to <"
sidebar:
  label: csrfMetaTags()
  order: 0
---

## Signature

`csrfMetaTags()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Include this in your layouts' <code>head</code> sections to include meta tags containing the authenticity token for use by JavaScript AJAX requests needing to <code>POST</code> data to your application.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `encode` | `boolean` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>&lt;head&gt;
  #csrfMetaTags()#
&lt;/head&gt;</code></pre>
