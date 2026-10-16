---
title: distanceOfTimeInWords()
description: "Pass in two dates to this method, and it will return a string describing the difference between them."
sidebar:
  label: distanceOfTimeInWords()
  order: 0
---

## Signature

`distanceOfTimeInWords()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** Date Functions

## Description

Pass in two dates to this method, and it will return a string describing the difference between them.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `fromTime` | `date` | yes | — | Date to compare from. |
| `toTime` | `date` | yes | — | Date to compare to. |
| `includeSeconds` | `boolean` | no | `false` | Whether or not to include the number of seconds in the returned string. |

</div>

## Examples

<pre><code class='javascript'>// 1. Compare two dates about a month apart
rightNow = Now();
aWhileAgo = DateAdd(&quot;d&quot;, -30, rightNow);
writeOutput(distanceOfTimeInWords(aWhileAgo, rightNow));
// -&gt; &quot;about 1 month&quot;

// 2. Show a short gap with seconds included
justNow = Now();
fiveSecondsAgo = DateAdd(&quot;s&quot;, -5, justNow);
writeOutput(distanceOfTimeInWords(fiveSecondsAgo, justNow, includeSeconds=true));
// -&gt; &quot;less than 5 seconds&quot;

// 3. Show various time ranges
now = Now();
writeOutput(distanceOfTimeInWords(DateAdd(&quot;n&quot;, -2, now), now));
// -&gt; &quot;2 minutes&quot;

writeOutput(distanceOfTimeInWords(DateAdd(&quot;h&quot;, -3, now), now));
// -&gt; &quot;about 3 hours&quot;

writeOutput(distanceOfTimeInWords(DateAdd(&quot;d&quot;, -5, now), now));
// -&gt; &quot;5 days&quot;

writeOutput(distanceOfTimeInWords(DateAdd(&quot;yyyy&quot;, -2, now), now));
// -&gt; &quot;over 2 years&quot;
</code></pre>
