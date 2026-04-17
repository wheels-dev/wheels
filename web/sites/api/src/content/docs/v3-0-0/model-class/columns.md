---
title: columns()
description: "Returns an array of database column names for the table associated with the model. This method excludes calculated or transient properties that are defined in t"
sidebar:
  label: columns()
  order: 0
---

## Signature

`columns()` — returns `array`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns an array of database column names for the table associated with the model. This method excludes calculated or transient properties that are defined in the model but not stored in the database.




## Examples

<pre><code class='javascript'>1. Get an array of columns for a model
userModel = model("user");
columnArray = userModel.columns();

writeDump(columnArray);
// Might output: ["id", "first_name", "last_name", "email", "created_at", "updated_at"]

2. Loop through the columns for dynamic processing
userModel = model("user");
for(column in userModel.columns()) {
    writeOutput("Column: #column#<br>");
}</code></pre>
