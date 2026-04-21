---
title: timeAgoInWords()
description: "Returns a human-friendly string describing the approximate time difference between two dates (defaults to comparing against the current time)."
sidebar:
  label: timeAgoInWords()
  order: 0
---

## Signature

`timeAgoInWords()` — returns `any`

**Available in:** `controller`, `model`, `test`, `migrator`, `migration`, `tabledefinition`
**Category:** Date Functions

## Description

Returns a human-friendly string describing the approximate time difference between two dates (defaults to comparing against the current time).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `fromTime` | `date` | yes | — | Date to compare from. |
| `includeSeconds` | `boolean` | no | `false` | Whether or not to include the number of seconds in the returned string. |
| `toTime` | `date` | no | `[runtime expression]` | Date to compare to. |

</div>

## Examples

<pre><code class='javascript'>1. Example in a controller (outputs: &quot;3 months&quot;)
aWhileAgo = DateAdd(&quot;d&quot;, -90, Now());
timeAgoInWords(aWhileAgo)

2. Including seconds (outputs: &quot;less than 5 seconds&quot;)
timeAgoInWords(DateAdd(&quot;s&quot;, -3, Now()), includeSeconds=true)

3. Comparing two specific dates (Outputs: &quot;5 months&quot;)
past = CreateDateTime(2024, 01, 01, 12, 0, 0);
future = CreateDateTime(2024, 06, 01, 12, 0, 0);
timeAgoInWords(fromTime=past, toTime=future)
</code></pre>
