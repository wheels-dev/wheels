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
You only need to use this method when you want to override the default object relational mapping that CFWheels performs.



## Parameters

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

## Examples

<pre><code class='javascript'>// Tell Wheels that when we are referring to `firstName` in the CFML code, it should translate to the `STR_USERS_FNAME` column when interacting with the database instead of the default (which would be the `firstname` column)
property(name=&quot;firstName&quot;, column=&quot;STR_USERS_FNAME&quot;);

// Tell Wheels that when we are referring to `fullName` in the CFML code, it should concatenate the `STR_USERS_FNAME` and `STR_USERS_LNAME` columns
property(name=&quot;fullName&quot;, sql=&quot;STR_USERS_FNAME + ' ' + STR_USERS_LNAME&quot;);

// Tell Wheels that when displaying error messages or labels for form fields, we want to use `First name(s)` as the label for the `STR_USERS_FNAME` column
property(name=&quot;firstName&quot;, label=&quot;First name(s)&quot;);

// Tell Wheels that when creating new objects, we want them to be auto-populated with a `firstName` property of value `Dave`
property(name=&quot;firstName&quot;, defaultValue=&quot;Dave&quot;);</code></pre>
