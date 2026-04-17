---
title: execute()
description: "execute() allows you to run a raw SQL query directly from a migration file. This is useful when you need to perform operations that aren’t easily handled by the"
sidebar:
  label: execute()
  order: 0
---

## Signature

`execute()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

execute() allows you to run a raw SQL query directly from a migration file. This is useful when you need to perform operations that aren’t easily handled by the built-in migration methods like createTable() or addColumn(). Only available in a migration CFC



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `sql` | `string` | yes | — | Arbitary SQL String |

## Examples

<pre><code class='javascript'>&lt;cfscript&gt;
function up() {
  transaction {
     // Execute a raw SQL statement
     execute(sql=&quot;INSERT INTO users (firstname, lastname, email) VALUES ('John', 'Doe', 'john@example.com')&quot;);
  }
}
&lt;/cfscript&gt;
</code></pre>
