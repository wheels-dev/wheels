---
title: stripLinks()
description: "Removes all links from an HTML string, leaving just the link text."
sidebar:
  label: stripLinks()
  order: 0
---

## Signature

`stripLinks()` — returns `string`

**Available in:** `controller`
**Category:** Sanitization Functions

## Description

Removes all links from an HTML string, leaving just the link text.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `html` | `string` | yes | — | The HTML to remove links from. |
| `encode` | `boolean` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre>&lt;!--- Will output: &lt;strong&gt;Wheels&lt;/strong&gt; is a framework for ColdFusion. ---&gt;
#stripLinks('&lt;strong&gt;Wheels&lt;/strong&gt; is a framework for &lt;a href=&quot;http://www.adobe.com/products/coldfusion&quot;&gt;ColdFusion&lt;/a&gt;.')#</pre>
