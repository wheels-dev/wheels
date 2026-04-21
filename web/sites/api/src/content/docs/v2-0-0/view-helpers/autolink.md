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

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to create links in. |
| `link` | `string` | no | `all` | Whether to link URLs, email addresses or both. Possible values are: `all` (default), `URLs` and `emailAddresses`. |
| `relative` | `boolean` | no | `true` | Should we auto-link relative urls. |
| `encode` | `boolean` | no | `true` | When set to `true`, encodes tag content, attribute values, and URLs so that Cross Site Scripting (XSS) attacks can be prevented. Set to `attributes` to only encode attribute values and not tag content. |

</div>

## Examples

<pre>&lt;!--- Will output: Download CFWheels from &lt;a href=&quot;http://cfwheels.org/download&quot;&gt;http://cfwheels.org/download&lt;/a&gt; ---&gt;
#autoLink(&quot;Download CFWheels from http://cfwheels.org/download&quot;)#

&lt;!--- Will output: Email us at &lt;a href=&quot;mailto:info@cfwheels.org&quot;&gt;info@cfwheels.org&lt;/a&gt; ---&gt;
#autoLink(&quot;Email us at info@cfwheels.org&quot;)#</pre>
