---
title: updateProperty()
description: "Updates a single property on a model object and saves the record immediately without running the normal validation procedures. This method is particularly usefu"
sidebar:
  label: updateProperty()
  order: 0
---

## Signature

`updateProperty()` — returns `boolean`

**Available in:** `model`
**Category:** CRUD Functions

## Description

Updates a single property on a model object and saves the record immediately without running the normal validation procedures. This method is particularly useful for quickly updating flags or boolean values on existing records where full validation is not necessary. You can control transaction behavior, parameterization, and callback execution when using this method.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Name of the property to update the value for globally. |
| `value` | `any` | no | — | Value to set on the given property globally. |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |

## Examples

<pre><code class='javascript'>1. Update a single property on an existing product
product = model("product").findByKey(56);
product.updateProperty("new", 1);

2. Update a boolean flag without callbacks or validations
user = model("user").findByKey(42);
user.updateProperty(property="isActive", value=false, callbacks=false);</code></pre>
