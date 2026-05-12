---
title: distanceOfTimeInWords()
description: "Pass in two dates to this method, and it will return a string describing the difference between them."
sidebar:
  label: distanceOfTimeInWords()
  order: 0
---

## Signature

`distanceOfTimeInWords()` — returns `any`




## Description

Pass in two dates to this method, and it will return a string describing the difference between them.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `fromTime` | `date` | yes | — | Date to compare from.. |
| `toTime` | `date` | yes | `,` | Date to compare to. |
| `includeSeconds` | `boolean` | yes | `false` | Whether or not to include the number of seconds in the returned string. |

</div>

## Examples

<pre>distanceOfTimeInWords(fromTime, toTime [, includeSeconds ]) &lt;cfset aWhileAgo = Now() - 30&gt;
&lt;cfset rightNow = Now()&gt;
&lt;cfoutput&gt;#distanceOfTimeInWords(aWhileAgo, rightNow)#&lt;/cfoutput&gt;</pre>
