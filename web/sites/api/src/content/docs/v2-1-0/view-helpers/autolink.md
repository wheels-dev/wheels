---
title: autoLink()
description: "Turns all URLs and email addresses into links."
sidebar:
  label: autoLink()
  order: 0
---

## Signature

`autoLink()` — returns `string`

**Available in:** `controller`
**Category:** Link Functions

## Description

Turns all URLs and email addresses into links.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to create links in. |
| `link` | `string` | no | `all` | Whether to link URLs, email addresses or both. Possible values are: `all` (default), `URLs` and `emailAddresses`. |
| `relative` | `boolean` | no | `true` | Should we auto-link relative urls. |
| `encode` | `boolean` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |

## Examples

<pre><code class='javascript'>&lt;!--- Will output: Download CFWheels from &lt;a href=&quot;http://cfwheels.org/download&quot;&gt;http://cfwheels.org/download&lt;/a&gt; ---&gt;
#autoLink(&quot;Download CFWheels from http://cfwheels.org/download&quot;)#

&lt;!--- Will output: Email us at &lt;a href=&quot;mailto:info@cfwheels.org&quot;&gt;info@cfwheels.org&lt;/a&gt; ---&gt;
#autoLink(&quot;Email us at info@cfwheels.org&quot;)#</code></pre>
