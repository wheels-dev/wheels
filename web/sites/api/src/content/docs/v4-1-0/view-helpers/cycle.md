---
title: cycle()
description: "Cycles through list values every time it is called."
sidebar:
  label: cycle()
  order: 0
---

## Signature

`cycle()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Cycles through list values every time it is called.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `values` | `string` | yes | — | List of values to cycle through. |
| `name` | `string` | no | `default` | Name to give the cycle. Useful when you use multiple cycles on a page. |

</div>

## Examples

<pre><code class='javascript'>// 1. Alternate CSS classes on table rows
// Outputs &quot;odd&quot; on the first row, &quot;even&quot; on the second, &quot;odd&quot; on the third, etc.
&lt;table&gt;
	&lt;thead&gt;
		&lt;tr&gt;
			&lt;th&gt;Name&lt;/th&gt;
			&lt;th&gt;Phone&lt;/th&gt;
		&lt;/tr&gt;
	&lt;/thead&gt;
	&lt;tbody&gt;
		&lt;cfoutput query=&quot;employees&quot;&gt;
			&lt;tr class=&quot;#cycle(&quot;odd,even&quot;)#&quot;&gt;
				&lt;td&gt;#employees.name#&lt;/td&gt;
				&lt;td&gt;#employees.phone#&lt;/td&gt;
			&lt;/tr&gt;
		&lt;/cfoutput&gt;
	&lt;/tbody&gt;
&lt;/table&gt;

// 2. Use named cycles when running multiple cycles simultaneously
// Cycle &quot;row&quot; and &quot;highlight&quot; advance independently
&lt;cfoutput query=&quot;employees&quot;&gt;
	&lt;cfset rowClass = cycle(values=&quot;even,odd&quot;, name=&quot;row&quot;)&gt;
	&lt;cfset hlClass = cycle(values=&quot;highlight,normal,normal&quot;, name=&quot;highlight&quot;)&gt;
	&lt;tr class=&quot;#rowClass# #hlClass#&quot;&gt;
		&lt;td&gt;#employees.name#&lt;/td&gt;
	&lt;/tr&gt;
&lt;/cfoutput&gt;

// 3. Reset a cycle so it starts over from the first value
&lt;cfoutput query=&quot;departments&quot; group=&quot;departmentId&quot;&gt;
	&lt;div class=&quot;#cycle(values=&quot;even,odd&quot;, name=&quot;row&quot;)#&quot;&gt;
		&lt;ul&gt;
			&lt;cfoutput&gt;
				&lt;cfset rank = cycle(values=&quot;president,vice-president,director,manager,specialist,intern&quot;, name=&quot;position&quot;)&gt;
				&lt;li class=&quot;#rank#&quot;&gt;#employees.name#&lt;/li&gt;
			&lt;/cfoutput&gt;
		&lt;/ul&gt;
	&lt;/div&gt;
	&lt;cfset resetCycle(&quot;position&quot;)&gt;
&lt;/cfoutput&gt;
</code></pre>
