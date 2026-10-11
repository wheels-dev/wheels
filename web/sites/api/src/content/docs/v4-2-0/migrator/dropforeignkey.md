---
title: dropForeignKey()
description: "Drops a foreign key constraint from the database"
sidebar:
  label: dropForeignKey()
  order: 0
---

## Signature

`dropForeignKey()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Drops a foreign key constraint from the database
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `table` | `string` | yes | — | The table name to perform the operation on |
| `keyName` | `string` | yes | — | the name of the key to drop |

</div>

## Examples

<pre><code class='javascript'>// 1. Drop a foreign key constraint by its explicit name
// In the down() function, remove a foreign key added in up()
dropForeignKey(table=&quot;orders&quot;, keyName=&quot;FK_orders_customers&quot;);

// 2. Drop a foreign key that was created via addReference()
// addReference() creates keys named FK_&lt;table&gt;_&lt;pluralizedReference&gt;
// So addReference(table=&quot;comments&quot;, referenceName=&quot;post&quot;) creates &quot;FK_comments_posts&quot;
dropForeignKey(table=&quot;comments&quot;, keyName=&quot;FK_comments_posts&quot;);

// 3. Use inside a migration's down() to reverse an addForeignKey() call
// up() called: addForeignKey(table=&quot;profiles&quot;, referenceTable=&quot;users&quot;, column=&quot;userId&quot;, referenceColumn=&quot;id&quot;)
// down() reverses it:
dropForeignKey(table=&quot;profiles&quot;, keyName=&quot;FK_profiles_users&quot;);
</code></pre>
