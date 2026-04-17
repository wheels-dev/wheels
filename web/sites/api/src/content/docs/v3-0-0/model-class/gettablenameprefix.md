---
title: getTableNamePrefix()
description: "Returns the table name prefix that is set for the current model. This is useful when your database tables share a common prefix, and you need to construct queri"
sidebar:
  label: getTableNamePrefix()
  order: 0
---

## Signature

`getTableNamePrefix()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the table name prefix that is set for the current model. This is useful when your database tables share a common prefix, and you need to construct queries dynamically or perform operations that require the full table name. By using this function, you ensure consistency and avoid hardcoding table prefixes in your queries.




## Examples

<pre><code class='javascript'>1. Get the table name prefix for the current model
prefix = model("user").getTableNamePrefix();
writeOutput("Table prefix: " & prefix);

2. Get the table name prefix for this user when running a custom query.
&lt;cffunction name=&quot;getDisabledUsers&quot; returntype=&quot;query&quot;&gt;
	&lt;cfquery datasource=&quot;#get('dataSourceName')#&quot; name=&quot;local.disabledUsers&quot;&gt;
	SELECT *
	FROM #this.getTableNamePrefix()#users
	WHERE disabled = 1
	&lt;/cfquery&gt;
	&lt;cfreturn local.disabledUsers&gt;
&lt;/cffunction&gt;
</code></pre>
