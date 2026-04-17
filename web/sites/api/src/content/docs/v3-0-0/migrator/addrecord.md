---
title: addRecord()
description: "Inserts a new record into a table. This function is only available inside a migration CFC and is part of the Wheels migrator API. Useful for seeding initial dat"
sidebar:
  label: addRecord()
  order: 0
---

## Signature

`addRecord()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Inserts a new record into a table. This function is only available inside a migration CFC and is part of the Wheels migrator API. Useful for seeding initial data (like admin users, roles, or lookup values) alongside schema changes.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to add the record to |

## Examples

<pre><code class='javascript'>1. Add a single record
addRecord(
    table=&quot;people&quot;,
    id=1,
    title=&quot;Mr&quot;,
    firstname=&quot;Bruce&quot;,
    lastname=&quot;Wayne&quot;, 
    email=&quot;bruce@wayneenterprises.com&quot;,
    tel=&quot;555-67869099&quot;
);

Inserts one record into the people table.

2. Add a record with only required fields
addRecord(
    table=&quot;roles&quot;,
    id=1,
    name=&quot;Admin&quot;
);

Seeds an Admin role into the roles table.

3. Add a record with default values in schema
addRecord(
    table=&quot;users&quot;,
    email=&quot;new@example.com&quot;,
    firstName=&quot;new&quot;,
    lastName=&quot;user&quot;
);

Relies on schema defaults (e.g., isActive=true) for missing fields.

4. Add lookup data
addRecord(
    table=&quot;statuses&quot;,
    id=1,
    name=&quot;Pending&quot;
);
addRecord(
    table=&quot;statuses&quot;,
    id=2,
    name=&quot;Approved&quot;
);
addRecord(
    table=&quot;statuses&quot;,
    id=3,
    name=&quot;Rejected&quot;
);

Seeds reusable lookup/status values.

5. Add a record referencing another table
// Assuming user with ID=1 exists
addRecord(
    table=&quot;posts&quot;,
    id=1,
    title=&quot;First Post&quot;,
    content=&quot;Hello, Wheels!&quot;,
    userId=1
);

Creates a post tied to an existing user.</code></pre>
