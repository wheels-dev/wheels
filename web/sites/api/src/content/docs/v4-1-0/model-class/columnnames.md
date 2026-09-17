---
title: columnNames()
description: "Returns a list of column names in the table mapped to this model."
sidebar:
  label: columnNames()
  order: 0
---

## Signature

`columnNames()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a list of column names in the table mapped to this model.
The list is ordered according to the columns' ordinal positions in the database table.




## Examples

<pre><code class='javascript'>// 1. Get the list of column names for the User model
cols = model(&quot;User&quot;).columnNames();
// cols -&gt; &quot;id,firstName,lastName,email,createdAt,updatedAt,deletedAt&quot;

// 2. Check whether a specific column exists in the table
if (listFindNoCase(model(&quot;User&quot;).columnNames(), &quot;email&quot;)) {
    writeOutput(&quot;The users table has an email column.&quot;);
}

// 3. Iterate over every column name
for (col in listToArray(model(&quot;User&quot;).columnNames())) {
    writeOutput(col);
}
</code></pre>
