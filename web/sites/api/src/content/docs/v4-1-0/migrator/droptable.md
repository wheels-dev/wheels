---
title: dropTable()
description: "Drops a table from the database"
sidebar:
  label: dropTable()
  order: 0
---

## Signature

`dropTable()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Drops a table from the database
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the table to drop |

</div>

## Examples

<pre><code class='javascript'>// 1. Drop a table in the down() migration (reversing a createTable in up())
component extends=&quot;wheels.migrator.Migration&quot; hint=&quot;Add products table&quot; {

	function up() {
		t = createTable(name=&quot;products&quot;);
		t.string(columnNames=&quot;name&quot;, allowNull=false);
		t.decimal(columnNames=&quot;price&quot;, precision=10, scale=2);
		t.boolean(columnNames=&quot;active&quot;, default=1);
		t.timestamps();
		t.create();
	}

	function down() {
		dropTable(&quot;products&quot;);
	}

}

// 2. Drop multiple tables in a single down() migration
component extends=&quot;wheels.migrator.Migration&quot; hint=&quot;Add orders and line items tables&quot; {

	function up() {
		t = createTable(name=&quot;lineItems&quot;);
		t.integer(columnNames=&quot;orderId&quot;);
		t.integer(columnNames=&quot;productId&quot;);
		t.integer(columnNames=&quot;quantity&quot;);
		t.timestamps();
		t.create();

		t = createTable(name=&quot;orders&quot;);
		t.integer(columnNames=&quot;userId&quot;);
		t.string(columnNames=&quot;status&quot;);
		t.timestamps();
		t.create();
	}

	function down() {
		dropTable(&quot;lineItems&quot;);
		dropTable(&quot;orders&quot;);
	}

}
</code></pre>
