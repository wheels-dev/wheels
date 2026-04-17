---
title: resetCycle()
description: "Resets a cycle so that it starts from the first list value the next time it is called."
sidebar:
  label: resetCycle()
  order: 0
---

## Signature

`resetCycle()` — returns `any`




## Description

Resets a cycle so that it starts from the first list value the next time it is called.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | `default` | The name of the cycle to reset. |

## Examples

<pre>&lt;!--- alternating row colors and shrinking emphasis ---&gt;
&lt;cfoutput query=&quot;employees&quot; group=&quot;departmentId&quot;&gt;
	&lt;div class=&quot;#cycle(values=&quot;even,odd&quot;, name=&quot;row&quot;)#&quot;&gt;
		&lt;ul&gt;
			&lt;cfoutput&gt;
				&lt;cfset rank = cycle(values=&quot;president,vice-president,director,manager,specialist,intern&quot;, name=&quot;position&quot;)&gt;
				&lt;li class=&quot;#rank#&quot;&gt;#categories.categoryName#&lt;/li&gt;
				&lt;cfset resetCycle(&quot;emphasis&quot;)&gt;
			&lt;/cfoutput&gt;
		&lt;/ul&gt;
	&lt;/div&gt;
&lt;/cfoutput&gt;</pre>
