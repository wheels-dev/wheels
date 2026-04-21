---
title: timeUntilInWords()
description: "Returns a human-readable string describing the approximate time difference between the current date (or another starting point you provide) and a future date. I"
sidebar:
  label: timeUntilInWords()
  order: 0
---

## Signature

`timeUntilInWords()` — returns `string`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Date Functions

## Description

Returns a human-readable string describing the approximate time difference between the current date (or another starting point you provide) and a future date. It is the inverse of <code>timeAgoInWords()</code>, focusing on how long until something happens instead of how long ago it occurred. You can optionally include seconds for more precise descriptions.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `toTime` | `date` | yes | — | Date to compare to. |
| `includeSeconds` | `boolean` | no | `false` | Whether or not to include the number of seconds in the returned string. |
| `fromTime` | `date` | no | `[runtime expression]` | Date to compare from. |

</div>

## Examples

<pre><code class='javascript'>1. Example in a controller (outputs: &quot;about 1 year&quot;)
aLittleAhead = DateAdd(&quot;d&quot;, 365, Now());
timeUntilInWords(aLittleAhead)

2. Including seconds (outputs: &quot;less than 5 seconds&quot;)
timeUntilInWords(DateAdd(&quot;s&quot;, 3, Now()), includeSeconds=true)

3. Comparing between two specific dates (Outputs: &quot;5 months&quot;)
fromDate = CreateDateTime(2024, 01, 01, 12, 0, 0);
toDate = CreateDateTime(2024, 06, 01, 12, 0, 0);
timeUntilInWords(toTime=toDate, fromTime=fromDate)
</code></pre>
