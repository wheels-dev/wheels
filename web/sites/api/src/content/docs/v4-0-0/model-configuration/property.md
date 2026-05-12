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

