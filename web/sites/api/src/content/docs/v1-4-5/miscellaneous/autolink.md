---
title: autoLink()
description: "Turns all URLs and email addresses into hyperlinks."
sidebar:
  label: autoLink()
  order: 0
---

## Signature

`autoLink()` — returns `any`




## Description

Turns all URLs and email addresses into hyperlinks.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to create links in. |
| `link` | `string` | yes | `all` | Whether to link URLs, email addresses or both. Possible values are: all (default), URLs and emailAddresses. |
| `relative` | `boolean` | yes | `true` | Should we autolink relative urls |

</div>

## Examples

<pre>#autoLink(&quot;Download CFWheels from http://cfwheels.org/download&quot;)#
-&gt; Download CFWheels from &lt;a href=&quot;http://cfwheels.org/download&quot;&gt;http://cfwheels.org/download&lt;/a&gt;

#autoLink(&quot;Email us at info@cfwheels.org&quot;)#
-&gt; Email us at &lt;a href=&quot;mailto:info@cfwheels.org&quot;&gt;info@cfwheels.org&lt;/a&gt;</pre>
