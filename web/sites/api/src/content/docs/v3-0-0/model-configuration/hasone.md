---
title: hasOne()
description: "Defines a one-to-one relationship between two models. It means each instance of this model is linked to exactly one record in another model. By default, Wheels"
sidebar:
  label: hasOne()
  order: 0
---

## Signature

`hasOne()` — returns `void`

**Available in:** `model`
**Category:** Association Functions

## Description

Defines a one-to-one relationship between two models. It means each instance of this model is linked to exactly one record in another model. By default, Wheels infers table and key names, but you can customize them with arguments like foreignKey, joinKey, and joinType.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Gives the association a name that you refer to when working with the association (in the `include` argument to `findAll`, to name one example). |
| `modelName` | `string` | no | — | Name of associated model (usually not needed if you follow Wheels conventions because the model name will be deduced from the `name` argument). |
| `foreignKey` | `string` | no | — | Foreign key property name (usually not needed if you follow Wheels conventions since the foreign key name will be deduced from the `name` argument). |
| `joinKey` | `string` | no | — | Column name to join to if not the primary key (usually not needed if you follow Wheels conventions since the join key will be the table's primary key/keys). |
| `joinType` | `string` | no | `outer` | Use to set the join type when joining associated tables. Possible values are `inner` (for `INNER JOIN`) and `outer` (for `LEFT OUTER JOIN`). |
| `dependent` | `string` | no | `false` | Defines how to handle dependent model objects when you delete an object from this model. `delete` / `deleteAll` deletes the record(s) (`deleteAll` bypasses object instantiation). `remove` / `removeAll` sets the forein key field(s) to `NULL` (`removeAll` bypasses object instantiation). |

</div>

## Examples

<pre><code class='javascript'>1. Basic one-to-one association

// A User has one Profile. The profiles table has userId as the foreign key.
// In app/models/User.cfc
hasOne(&quot;profile&quot;);

2. Strict inner join

// Force that every Employee must have one PayrollRecord.
// In app/models/Employee.cfc
hasOne(name=&quot;payrollRecord&quot;, joinType=&quot;inner&quot;);

// If there is no matching payrollRecord, the employee will not appear in queries using this association.

3. Auto-delete dependent record

// Delete the Profile when the User is deleted.
// In app/models/User.cfc
hasOne(name=&quot;profile&quot;, dependent=&quot;delete&quot;);

4. Custom foreign key

// If the foreign key doesn’t follow Wheels’ naming conventions.
// For example, Driver has one License, but the foreign key column is driver_ref.
// In app/models/Driver.cfc
hasOne(name=&quot;license&quot;, foreignKey=&quot;driver_ref&quot;);

5. Using joinKey for non-standard PK

// If the Company table uses companyCode instead of id as the primary key, and the Address table has companyCode as the foreign key:
// In app/models/Company.cfc
hasOne(name=&quot;address&quot;, joinKey=&quot;companyCode&quot;);
</code></pre>
