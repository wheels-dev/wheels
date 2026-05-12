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
