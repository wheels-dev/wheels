---
title: getTableNamePrefix()
description: "Returns the table name prefix set for the table."
sidebar:
  label: getTableNamePrefix()
  order: 0
---

## Signature

`getTableNamePrefix()` — returns `any`




## Description

Returns the table name prefix set for the table.


## Examples

<pre>getTableNamePrefix() &lt;!--- Get the table name prefix for this user when running a custom query ---&gt;
&lt;cffunction name=&quot;getDisabledUsers&quot; returntype=&quot;query&quot;&gt;
    &lt;cfset var loc = {}&gt;
    &lt;cfquery datasource=&quot;#get('dataSourceName')#&quot; name=&quot;loc.disabledUsers&quot;&gt;
        SELECT
            *
        FROM
            #this.getTableNamePrefix()#users
        WHERE
            disabled = 1
    &lt;/cfquery&gt;
    &lt;cfreturn loc.disabledUsers&gt;
&lt;/cffunction&gt;</pre>
