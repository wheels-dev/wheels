---
title: timeAgoInWords()
description: "Returns a string describing the approximate time difference between the date passed in and the current date."
sidebar:
  label: timeAgoInWords()
  order: 0
---

## Signature

`timeAgoInWords()` — returns `any`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Date Functions

## Description

Returns a string describing the approximate time difference between the date passed in and the current date.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `fromTime` | `date` | yes | — | Date to compare from. |
| `includeSeconds` | `boolean` | no | `false` | Whether or not to include the number of seconds in the returned string. |
| `toTime` | `date` | no | `[runtime expression]` | Date to compare to. |

</div>

## Examples

<pre><code class='javascript'>// 1. Show how long ago a date was (relative to now)
aWhileAgo = DateAdd(&quot;d&quot;, -90, Now());
// Returns something like &quot;3 months&quot;
writeOutput(timeAgoInWords(aWhileAgo));

// 2. Include seconds for a very recent timestamp
justNow = DateAdd(&quot;s&quot;, -8, Now());
// Returns &quot;less than 10 seconds&quot;
writeOutput(timeAgoInWords(fromTime=justNow, includeSeconds=true));

// 3. Compare against a specific reference point instead of now
postDate = CreateDateTime(2024, 1, 15, 9, 0, 0);
referenceDate = CreateDateTime(2024, 3, 20, 9, 0, 0);
// Returns &quot;about 2 months&quot;
writeOutput(timeAgoInWords(fromTime=postDate, toTime=referenceDate));
</code></pre>
