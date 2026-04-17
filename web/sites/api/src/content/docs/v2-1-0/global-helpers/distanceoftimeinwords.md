---
title: distanceOfTimeInWords()
description: "Pass in two dates to this method, and it will return a string describing the difference between them."
sidebar:
  label: distanceOfTimeInWords()
  order: 0
---

## Signature

`distanceOfTimeInWords()` — returns `string`

**Available in:** `controller`, `model`, `migrator`, `migration`, `tabledefinition`
**Category:** Date Functions

## Description

Pass in two dates to this method, and it will return a string describing the difference between them.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `fromTime` | `date` | yes | — | Date to compare from. |
| `toTime` | `date` | yes | — | Date to compare to. |
| `includeSeconds` | `boolean` | no | `false` | Whether or not to include the number of seconds in the returned string. |

## Examples

<pre><code class='javascript'>// Controller code.
rightNow = Now();
aWhileAgo = DateAdd(&quot;d&quot;, -30, rightNow);

// View code.
&lt;!--- Will output: about 1 month ---&gt;
#distanceOfTimeInWords(aWhileAgo, rightNow)#
</code></pre>
