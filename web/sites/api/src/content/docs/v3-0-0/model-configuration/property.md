---
title: property()
description: "Lets you customize how model properties map to database columns or SQL expressions. By default, Wheels automatically maps a model’s property name to the column"
sidebar:
  label: property()
  order: 0
---

## Signature

`property()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Lets you customize how model properties map to database columns or SQL expressions. By default, Wheels automatically maps a model’s property name to the column with the same name in the table. However, when your database uses non-standard column names, calculated values, or requires custom behavior, you can use property() to override the default mapping.



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

<pre><code class='javascript'>1. Tell Wheels that when we are referring to `firstName` in the CFML code, it should translate to the `STR_USERS_FNAME` column when interacting with the database instead of the default (which would be the `firstname` column)
property(name=&quot;firstName&quot;, column=&quot;STR_USERS_FNAME&quot;);

2. Tell Wheels that when we are referring to `fullName` in the CFML code, it should concatenate the `STR_USERS_FNAME` and `STR_USERS_LNAME` columns
property(name=&quot;fullName&quot;, sql=&quot;STR_USERS_FNAME + ' ' + STR_USERS_LNAME&quot;);

3. Tell Wheels that when displaying error messages or labels for form fields, we want to use `First name(s)` as the label for the `STR_USERS_FNAME` column
property(name=&quot;firstName&quot;, label=&quot;First name(s)&quot;);

4. Tell Wheels that when creating new objects, we want them to be auto-populated with a `firstName` property of value `Dave`
property(name=&quot;firstName&quot;, defaultValue=&quot;Dave&quot;);

5. Exclude property from SELECT queries
// Useful for virtual/computed properties you don’t want fetched from the DB
property(name="tempValue", select=false);

6. Override data type explicitly
property(name="isActive", dataType="boolean");
</code></pre>
