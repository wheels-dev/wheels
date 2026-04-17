---
title: resetCycle()
description: "Rsets a named cycle, allowing it to start from the first value the next time it is called. In Wheels, cycle() is often used to alternate values in a repeated pa"
sidebar:
  label: resetCycle()
  order: 0
---

## Signature

`resetCycle()` — returns `void`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Rsets a named cycle, allowing it to start from the first value the next time it is called. In Wheels, cycle() is often used to alternate values in a repeated pattern, such as CSS classes for table rows, positions, or emphasis levels. By calling resetCycle(), you ensure that the cycle begins again from its initial value, which is useful when looping through nested structures or when a new grouping starts.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | no | `default` | The name of the cycle to reset. |

## Examples

<pre><code class='javascript'>// alternating row colors and shrinking emphasis
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
