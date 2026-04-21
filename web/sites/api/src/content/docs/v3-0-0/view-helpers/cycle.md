---
title: cycle()
description: "cycle() is a view helper used to loop through a list of values sequentially, returning the next value each time it’s called. This is especially useful for thing"
sidebar:
  label: cycle()
  order: 0
---

## Signature

`cycle()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

cycle() is a view helper used to loop through a list of values sequentially, returning the next value each time it’s called. This is especially useful for things like alternating row colors in tables or assigning sequential classes in repeated HTML elements.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `values` | `string` | yes | — | List of values to cycle through. |
| `name` | `string` | no | `default` | Name to give the cycle. Useful when you use multiple cycles on a page. |

</div>

## Examples

<pre><code class='javascript'>&lt;!--- Alternating table row colors ---&gt;
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

&lt;!--- Alternating row colors and shrinking emphasis ---&gt;
&lt;cfoutput query=&quot;employees&quot; group=&quot;departmentId&quot;&gt;
	&lt;div class=&quot;#cycle(values=&quot;even,odd&quot;, name=&quot;row&quot;)#&quot;&gt;
		&lt;ul&gt;
			&lt;cfoutput&gt;
				rank = cycle(values=&quot;president,vice-president,director,manager,specialist,intern&quot;, name=&quot;position&quot;)&gt;
				&lt;li class=&quot;#rank#&quot;&gt;#categories.categoryName#&lt;/li&gt;
				resetCycle(&quot;emphasis&quot;)&gt;
			&lt;/cfoutput&gt;
		&lt;/ul&gt;
	&lt;/div&gt;
&lt;/cfoutput&gt;</code></pre>
