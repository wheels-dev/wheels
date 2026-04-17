---
title: columnNames()
description: "Returns a list of column names in the table mapped to this model. The list is ordered according to the columns' ordinal positions in the database table."
sidebar:
  label: columnNames()
  order: 0
---

## Signature

`columnNames()` — returns `any`




## Description

Returns a list of column names in the table mapped to this model. The list is ordered according to the columns' ordinal positions in the database table.


## Examples

<pre>columnNames() &lt;!--- Get a list of all the column names in the table mapped to the `author` model ---&gt;
&lt;cfset columns = model(&quot;author&quot;).columnNames()&gt;</pre>
