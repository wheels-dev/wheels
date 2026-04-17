---
title: timeUntilInWords()
description: "Returns a string describing the approximate time difference between the current date and the date passed in."
sidebar:
  label: timeUntilInWords()
  order: 0
---

## Signature

`timeUntilInWords()` — returns `string`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Date Functions

## Description

Returns a string describing the approximate time difference between the current date and the date passed in.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `toTime` | `date` | yes | — | Date to compare to. |
| `includeSeconds` | `boolean` | no | `false` | Whether or not to include the number of seconds in the returned string. |
| `fromTime` | `date` | no | `[runtime expression]` | Date to compare from. |

## Examples

<pre><code class='javascript'>// Controller code.
aLittleAhead = DateAdd(&quot;d&quot;, 365, Now());

// View code.
&lt;!--- Will output: about 1 year ---&gt;
#timeUntilInWords(aLittleAhead)#
</code></pre>
