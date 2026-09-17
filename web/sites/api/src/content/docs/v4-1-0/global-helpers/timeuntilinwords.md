---
title: timeUntilInWords()
description: "Returns a string describing the approximate time difference between the current date and the date passed in."
sidebar:
  label: timeUntilInWords()
  order: 0
---

## Signature

`timeUntilInWords()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Date Functions

## Description

Returns a string describing the approximate time difference between the current date and the date passed in.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `toTime` | `date` | yes | — | Date to compare to. |
| `includeSeconds` | `boolean` | no | `false` | Whether or not to include the number of seconds in the returned string. |
| `fromTime` | `date` | no | `[runtime expression]` | Date to compare from. |

</div>

## Examples

<pre><code class='javascript'>// 1. Show approximate time until a future date
nextYear = DateAdd(&quot;yyyy&quot;, 1, Now());
writeOutput(timeUntilInWords(nextYear));
// -&gt; &quot;about 1 year&quot;

// 2. Include seconds for a near-future time
soonish = DateAdd(&quot;s&quot;, 8, Now());
writeOutput(timeUntilInWords(toTime=soonish, includeSeconds=true));
// -&gt; &quot;less than 10 seconds&quot;

// 3. Compare two explicit dates (custom fromTime)
launchDate = CreateDate(2025, 6, 1);
deadline   = CreateDate(2025, 9, 15);
writeOutput(timeUntilInWords(toTime=deadline, fromTime=launchDate));
// -&gt; &quot;about 3 months&quot;
</code></pre>
