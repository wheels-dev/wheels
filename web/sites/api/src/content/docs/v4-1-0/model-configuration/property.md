---
title: property()
description: "Use this method to map an object property to either a table column with a different name than the property or to a SQL expression."
sidebar:
  label: property()
  order: 0
---

## Signature

`property()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Use this method to map an object property to either a table column with a different name than the property or to a SQL expression.
You only need to use this method when you want to override the default object relational mapping that Wheels performs.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | The name that you want to use for the column or SQL function result in the CFML code. |
| `column` | `string` | no | — | The name of the column in the database table to map the property to. |
| `sql` | `string` | no | — | An SQL expression to use to calculate the property value. |
| `label` | `string` | no | — | A custom label for this property to be referenced in the interface and error messages. |
| `defaultValue` | `string` | no | — | A default value for this property. |
| `select` | `boolean` | no | `true` | Whether to include this property by default in SELECT statements |
| `dataType` | `string` | no | `char` | Specify the column dataType for this property |
| `automaticValidations` | `boolean` | no | — | Enable / disable automatic validations for this property. |

</div>

## Examples

<pre><code class='javascript'>// 1. Map a CFML property name to a differently-named database column
// Tell Wheels that `firstName` in CFML maps to `STR_USERS_FNAME` in the database
// instead of the default `firstname` column
property(name=&quot;firstName&quot;, column=&quot;STR_USERS_FNAME&quot;);

// 2. Create a calculated property using a SQL expression
// `fullName` is derived by concatenating two columns at the database level
property(name=&quot;fullName&quot;, sql=&quot;STR_USERS_FNAME + ' ' + STR_USERS_LNAME&quot;);

// 3. Set a custom label used in form helpers and validation error messages
property(name=&quot;firstName&quot;, label=&quot;First name(s)&quot;);

// 4. Specify a default value applied when creating new objects
property(name=&quot;firstName&quot;, defaultValue=&quot;Dave&quot;);

// 5. Define a calculated property with a specific data type and exclude it from default SELECTs
// Useful when the SQL expression returns a numeric result or when you only need
// the value in specific queries
property(name=&quot;orderTotal&quot;, sql=&quot;SUM(line_items.price)&quot;, dataType=&quot;decimal&quot;, select=false);

// 6. Disable automatic validations for a specific property
// Wheels normally infers validations (e.g. string-length, numeric) from the column type;
// set automaticValidations=false to skip that for this property
property(name=&quot;legacyCode&quot;, automaticValidations=false);
</code></pre>
