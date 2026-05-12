---
title: deleteOne()
description: "Finds a single record based on conditions and deletes it. Returns true if deletion succeeds, false otherwise. It is useful when you want to remove one specific"
sidebar:
  label: deleteOne()
  order: 0
---

## Signature

`deleteOne()` — returns `boolean`

**Available in:** `model`
**Category:** Delete Functions

## Description

Finds a single record based on conditions and deletes it. Returns true if deletion succeeds, false otherwise. It is useful when you want to remove one specific record without fetching it manually first.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `where` | `string` | no | — | Maps to the `WHERE` clause of the query (or `HAVING` when necessary). The following operators are supported: `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `LIKE`, `NOT LIKE`, `IN`, `NOT IN`, `IS NULL`, `IS NOT NULL`, `AND`, and `OR` (note that the key words need to be written in upper case). You can also use parentheses to group statements. Nested queries not allowed. You do not need to specify the table name(s); Wheels will do that for you. |
| `order` | `string` | no | — | Maps to the `ORDER` BY clause of the query. You do not need to specify the table name(s); Wheels will do that for you. |
| `reload` | `boolean` | no | `false` | Set to `true` to force Wheels to query the database even though an identical query for this model may have been run in the same request. (The default in Wheels is to get the second query from the model's request-level cache.) |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |
| `useIndex` | `struct` | no | `[runtime expression]` | If you want to specify table index hints, pass in a structure of index names using your model names as the structure keys. Eg: `{user="idx_users", post="idx_posts"}`. This feature is only supported by MySQL and SQL Server. |
| `includeSoftDeletes` | `boolean` | no | `false` | Set to `true` to include soft-deleted records in the queries that this method runs. |
| `softDelete` | `boolean` | no | `true` | Set to `false` to permanently delete a record, even if it has a soft delete column. |

</div>

## Examples

<pre><code class='javascript'>Example 1: Delete the most recently signed-up user
&lt;cfscript&gt;
result = model("user").deleteOne(order="signupDate DESC");

if (result) {
    writeOutput("Deleted the most recently signed-up user.");
} else {
    writeOutput("No user found to delete.");
}
&lt;/cfscript&gt;

Deletes one record based on the order of signupDate descending.

Only the first matching record is deleted.

Example 2: Delete a specific user by condition
&lt;cfscript&gt;
result = model("user").deleteOne(where="email='test@example.com'");

writeOutput("Deletion status: #result#");
&lt;/cfscript&gt;

Finds a user with the email test@example.com and deletes it.

Example 3: Scoped delete via association
&lt;cfscript&gt;
// Assuming a hasOne association: user -&gt; profile
aUser = model("user").findByKey(params.userId);
aUser.deleteProfile(); // deletes the profile associated with this user
&lt;/cfscript&gt;

deleteProfile() internally calls model("profile").deleteOne(where="userId=#aUser.id#").
</code></pre>
