---
title: distanceOfTimeInWords()
description: "Pass in two dates to this method, and it will return a string describing the difference between them."
sidebar:
  label: distanceOfTimeInWords()
  order: 0
---

## Signature

`distanceOfTimeInWords()` — returns `string`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
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

<pre><code class='javascript'>Example 1: Basic usage
&lt;cfscript&gt;
rightNow = now();
aWhileAgo = dateAdd("d", -30, rightNow);

timeDifference = distanceOfTimeInWords(aWhileAgo, rightNow);
writeOutput(timeDifference); // Outputs: "about 1 month"
&lt;/cfscript&gt;

Calculates the difference between two dates.

Returns "about 1 month" because aWhileAgo is 30 days before rightNow.

Example 2: Include seconds
&lt;cfscript&gt;
startTime = now();
endTime = dateAdd("s", 45, startTime);

timeDifference = distanceOfTimeInWords(startTime, endTime, true);
writeOutput(timeDifference); // Outputs: "less than a minute" or "45 seconds" depending on Wheels version
&lt;/cfscript&gt;

Useful when you need a more precise human-readable difference for very short intervals.

Example 3: Past vs future dates
&lt;cfscript&gt;
pastDate = dateAdd("d", -10, now());
futureDate = dateAdd("d", 5, now());

writeOutput(distanceOfTimeInWords(pastDate, now()));   // "10 days"
writeOutput(distanceOfTimeInWords(now(), futureDate)); // "5 days"
&lt;/cfscript&gt;

Works regardless of the order of the dates.

Always returns a human-friendly description.</code></pre>
