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

<pre>// Get the table name prefix for this user when running a custom query.
&lt;cffunction name=&quot;getDisabledUsers&quot; returntype=&quot;query&quot;&gt;
	&lt;cfquery datasource=&quot;#get('dataSourceName')#&quot; name=&quot;local.disabledUsers&quot;&gt;
	SELECT *
	FROM #this.getTableNamePrefix()#users
	WHERE disabled = 1
	&lt;/cfquery&gt;
	&lt;cfreturn local.disabledUsers&gt;
&lt;/cffunction&gt;
</pre>
