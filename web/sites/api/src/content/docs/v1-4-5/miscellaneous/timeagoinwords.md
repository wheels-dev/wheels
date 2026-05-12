---
title: timeAgoInWords()
description: "Pass in a date to this method, and it will return a string describing the approximate time difference between that date and the current date."
sidebar:
  label: timeAgoInWords()
  order: 0
---

## Signature

`timeAgoInWords()` — returns `any`




## Description

Pass in a date to this method, and it will return a string describing the approximate time difference between that date and the current date.

## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `fromTime` | `date` | yes | — | Date to compare from.. |
| `includeSeconds` | `boolean` | yes | `false` | Whether or not to include the number of seconds in the returned string. |
| `toTime` | `date` | yes | `[runtime expression]` | Date to compare to. |

</div>

## Examples

<pre>timeAgoInWords(fromTime [, includeSeconds, toTime ]) &lt;cfset aWhileAgo = Now() - 30&gt;
&lt;cfoutput&gt;#timeAgoInWords(aWhileAgo)#&lt;/cfoutput&gt;</pre>
