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
| `encode` | `boolean` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre>&lt;head&gt;
  #csrfMetaTags()#
&lt;/head&gt;</pre>
