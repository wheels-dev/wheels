---
title: columnDataForProperty()
description: "Returns a struct containing metadata about a specific property in a model. This includes information such as type, constraints, default values, and other column"
sidebar:
  label: columnDataForProperty()
  order: 0
---

## Signature

`columnDataForProperty()` — returns `any`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a struct containing metadata about a specific property in a model. This includes information such as type, constraints, default values, and other column-specific details. It’s useful when you need to introspect the schema of your model dynamically.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

## Examples

<pre><code class='javascript'>1. Inspect a simple property
user = model("user").columnDataForProperty("email");

writeDump(user);

Output might include:
{
  "column": "email",
  "dataType": "string",
  "columnDefault": "",
  "nullable": "NO",
  "size": 255
}

2. Use column metadata for validation or dynamic forms
columns = model("product").columnDataForProperty("price");

if(columns.nullable EQ "NO" AND columns.dataType EQ "decimal") {
    writeOutput("Price is required and must be decimal.");
}</code></pre>
