---
title: flashKeep()
description: "The flashKeep() function allows you to preserve Flash data for one additional request. By default, Flash values are only available for the very next request; ca"
sidebar:
  label: flashKeep()
  order: 0
---

## Signature

`flashKeep()` — returns `void`

**Available in:** `controller`
**Category:** Flash Functions

## Description

The flashKeep() function allows you to preserve Flash data for one additional request. By default, Flash values are only available for the very next request; calling flashKeep() prevents them from being cleared after the current request. You can choose to keep the entire Flash or only specific keys. This is useful when you want messages or temporary data to persist through multiple redirects or page loads.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `string` | no | — |  |

## Examples

<pre><code class='javascript'>1. Keep the entire Flash for the next request
flashKeep();

2. Keep the &quot;error&quot; key in the Flash for the next request
flashKeep(&quot;error&quot;);

3. Keep both the &quot;error&quot; and &quot;success&quot; keys in the Flash for the next request
flashKeep(&quot;error,success&quot;);</code></pre>
