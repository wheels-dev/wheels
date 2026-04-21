---
title: flashKeep()
description: "Make the entire Flash or specific key in it stick around for one more request."
sidebar:
  label: flashKeep()
  order: 0
---

## Signature

`flashKeep()` — returns `void`

**Available in:** `controller`
**Category:** Flash Functions

## Description

Make the entire Flash or specific key in it stick around for one more request.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `key` | `string` | no | — |  |

</div>

## Examples

<pre>// Keep the entire Flash for the next request
flashKeep();

// Keep the &quot;error&quot; key in the Flash for the next request
flashKeep(&quot;error&quot;);

// Keep both the &quot;error&quot; and &quot;success&quot; keys in the Flash for the next request
flashKeep(&quot;error,success&quot;);</pre>
