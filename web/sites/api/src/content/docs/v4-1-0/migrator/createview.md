---
title: createView()
description: "Creates a view definition object to store view properties"
sidebar:
  label: createView()
  order: 0
---

## Signature

`createView()` — returns `ViewDefinition`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Creates a view definition object to store view properties
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the view to change properties on |

</div>

## Examples

<pre><code class='javascript'>// 1. Create a simple database view that joins users and roles
v = createView(name=&quot;userRoles&quot;);
v.selectStatement(sql=&quot;SELECT u.id, u.firstName, u.lastName, r.name AS roleName FROM users u INNER JOIN roles r ON u.roleId = r.id&quot;);
v.create();

// 2. Create a view for active (non-deleted) users using method chaining
createView(name=&quot;activeUsers&quot;)
    .selectStatement(sql=&quot;SELECT id, firstName, lastName, email FROM users WHERE deletedAt IS NULL&quot;)
    .create();

// 3. Full up/down migration using createView and dropView
component extends=&quot;wheels.migrator.Migration&quot; {
    function up() {
        createView(name=&quot;publishedArticles&quot;)
            .selectStatement(sql=&quot;SELECT id, title, body, authorId, publishedAt FROM articles WHERE publishedAt IS NOT NULL&quot;)
            .create();
    }
    function down() {
        dropView(name=&quot;publishedArticles&quot;);
    }
}
</code></pre>
