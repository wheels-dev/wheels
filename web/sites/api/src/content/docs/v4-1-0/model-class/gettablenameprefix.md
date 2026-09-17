---
title: getTableNamePrefix()
description: "Returns the table name prefix set for the table."
sidebar:
  label: getTableNamePrefix()
  order: 0
---

## Signature

`getTableNamePrefix()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the table name prefix set for the table.




## Examples

<pre><code class='javascript'>// 1. Use the table name prefix when running a custom query inside a model method
function getDisabledUsers() {
	local.q = queryExecute(
		&quot;SELECT * FROM #this.getTableNamePrefix()#users WHERE disabled = 1&quot;,
		[],
		{datasource: get(&quot;dataSourceName&quot;)}
	);
	return local.q;
}

// 2. Log the configured prefix to verify model setup
prefix = model(&quot;User&quot;).getTableNamePrefix();
// prefix -&gt; &quot;app_&quot; (or &quot;&quot; if none is set)
</code></pre>
