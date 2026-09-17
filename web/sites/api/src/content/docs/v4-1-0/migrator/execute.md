---
title: execute()
description: "Executes a raw sql query"
sidebar:
  label: execute()
  order: 0
---

## Signature

`execute()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Executes a raw sql query
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `sql` | `string` | yes | — | Arbitrary SQL String |

</div>

## Examples

<pre><code class='javascript'>// 1. Run a raw SQL statement during a migration
execute(sql = &quot;UPDATE users SET active = 1 WHERE active IS NULL&quot;);

// 2. Create a database view with raw SQL
execute(sql = &quot;CREATE VIEW active_users AS SELECT * FROM users WHERE active = 1&quot;);

// 3. Use execute() inside up() and down() to apply and reverse a custom SQL change
component extends=&quot;wheels.migrator.Migration&quot; {
    function up() {
        execute(sql = &quot;ALTER TABLE orders ADD COLUMN notes TEXT&quot;);
    }
    function down() {
        execute(sql = &quot;ALTER TABLE orders DROP COLUMN notes&quot;);
    }
}
</code></pre>
