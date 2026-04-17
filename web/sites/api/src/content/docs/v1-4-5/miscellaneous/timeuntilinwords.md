---
title: timeUntilInWords()
description: "Pass in a date to this method, and it will return a string describing the approximate time difference between the current date and that date."
sidebar:
  label: timeUntilInWords()
  order: 0
---

## Signature

`timeUntilInWords()` — returns `any`




## Description

Pass in a date to this method, and it will return a string describing the approximate time difference between the current date and that date.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `toTime` | `date` | yes | — | Date to compare to. |
| `includeSeconds` | `boolean` | yes | `false` | Whether or not to include the number of seconds in the returned string. |
| `fromTime` | `date` | yes | `[runtime expression]` | Date to compare from. |

## Examples

<pre>timeUntilInWords(toTime [, includeSeconds, fromTime ]) &lt;cfset aLittleAhead = Now() + 30&gt;
&lt;cfoutput&gt;#timeUntilInWords(aLittleAhead)#&lt;/cfoutput&gt;</pre>
