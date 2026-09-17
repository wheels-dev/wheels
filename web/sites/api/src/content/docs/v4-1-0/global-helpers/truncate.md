---
title: truncate()
description: "Truncates text to the specified length and replaces the last characters with the specified truncate string (which defaults to \"...\")."
sidebar:
  label: truncate()
  order: 0
---

## Signature

`truncate()` — returns `string`

**Available in:** `controller`, `model`, `mapper`, `migrator`, `migration`, `tabledefinition`
**Category:** String Functions

## Description

Truncates text to the specified length and replaces the last characters with the specified truncate string (which defaults to "...").



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | yes | — | The text to truncate. |
| `length` | `numeric` | no | `30` | Length to truncate the text to. |
| `truncateString` | `string` | no | `...` | String to replace the last characters with. |

</div>

## Examples

<pre><code class='javascript'>// 1. Truncate to a specific character length (defaults to &quot;...&quot; suffix)
truncated = truncate(text=&quot;CFWheels is a framework for ColdFusion&quot;, length=20);
// truncated -&gt; &quot;CFWheels is a fra...&quot;

// 2. Use a custom truncate string instead of the default ellipsis
truncated = truncate(text=&quot;CFWheels is a framework for ColdFusion&quot;, truncateString=&quot; (more)&quot;);
// truncated -&gt; &quot;CFWheels is a framework fo (more)&quot;

// 3. Text shorter than the length limit is returned unchanged
truncated = truncate(text=&quot;Hello&quot;, length=30);
// truncated -&gt; &quot;Hello&quot;
</code></pre>
