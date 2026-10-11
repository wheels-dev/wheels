---
title: resetCycle()
description: "Resets a cycle so that it starts from the first list value the next time it is called."
sidebar:
  label: resetCycle()
  order: 0
---

## Signature

`resetCycle()` — returns `void`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Resets a cycle so that it starts from the first list value the next time it is called.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | `default` | The name of the cycle to reset. |

</div>

## Examples

<pre><code class='javascript'>// 1. Reset the default cycle between grouped query sections
&lt;cfoutput query=&quot;posts&quot; group=&quot;categoryId&quot;&gt;
	resetCycle();
	&lt;cfoutput&gt;
		rowClass = cycle(values=&quot;even,odd&quot;);
		writeOutput(rowClass &amp; &quot;: &quot; &amp; posts.title);
	&lt;/cfoutput&gt;
&lt;/cfoutput&gt;

// 2. Reset a named cycle so it starts over for each department group
&lt;cfoutput query=&quot;employees&quot; group=&quot;departmentId&quot;&gt;
	resetCycle(&quot;position&quot;);
	&lt;cfoutput&gt;
		rank = cycle(values=&quot;manager,specialist,intern&quot;, name=&quot;position&quot;);
		writeOutput(employees.lastName &amp; &quot; - &quot; &amp; rank);
	&lt;/cfoutput&gt;
&lt;/cfoutput&gt;

// 3. Reset all cycles by name after rendering a section
resetCycle(&quot;row&quot;);
resetCycle(&quot;highlight&quot;);
</code></pre>
