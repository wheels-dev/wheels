---
title: addReference()
description: "Adds a reference column and a foreign key constraint to a table in one step. This is a shortcut for creating an integer column (e.g., userId) and then linking i"
sidebar:
  label: addReference()
  order: 0
---

## Signature

`addReference()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Adds a reference column and a foreign key constraint to a table in one step. This is a shortcut for creating an integer column (e.g., userId) and then linking it to another table using a foreign key. This function is only available inside a migration CFC and is part of the Wheels migrator API.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the operation on |
| `referenceName` | `string` | yes | — | The reference table name to perform the operation on |

## Examples

<pre><code class='javascript'>1. Add a user reference to orders
addReference(
    table=&quot;orders&quot;,
    referenceName=&quot;users&quot;
);

Adds a userId column to orders and creates a foreign key to users.id.

2. Add a post reference to comments
addReference(
    table=&quot;comments&quot;,
    referenceName=&quot;posts&quot;
);

Creates a postId column on comments and links it to posts.id.

3. Add references to multiple tables
addReference(table=&quot;enrollments&quot;, referenceName=&quot;students&quot;);
addReference(table=&quot;enrollments&quot;, referenceName=&quot;courses&quot;);

Adds both studentId and courseId to enrollments with foreign keys to students and courses.

4. Composite example (reference + other fields)
addColumn(table=&quot;votes&quot;, columnType=&quot;boolean&quot;, columnName=&quot;upvote&quot;, default=1);
addReference(table=&quot;votes&quot;, referenceName=&quot;users&quot;);
addReference(table=&quot;votes&quot;, referenceName=&quot;posts&quot;);

Builds a votes table that connects users and posts with foreign keys.</code></pre>
