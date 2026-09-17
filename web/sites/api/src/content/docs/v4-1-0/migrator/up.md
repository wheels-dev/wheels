---
title: up()
description: "Migrates up: will be executed when migrating your schema forward"
sidebar:
  label: up()
  order: 0
---

## Signature

`up()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Migrates up: will be executed when migrating your schema forward
Along with down(), these are the two main functions in any migration file
Only available in a migration CFC




## Examples

<pre><code class='javascript'>// 1. Create a new table (typical migration forward)
function up() {
	var state = {};
	transaction {
		try {
			t = createTable(name=&quot;posts&quot;);
			t.string(columnNames=&quot;title&quot;, limit=255);
			t.text(columnNames=&quot;body&quot;);
			t.boolean(columnNames=&quot;published&quot;, default=0);
			t.timestamps();
			t.create();
		} catch (any e) {
			state.exception = e;
		}

		if (structKeyExists(state, &quot;exception&quot;)) {
			transaction action=&quot;rollback&quot;;
			throw(
				errorCode = &quot;1&quot;,
				detail    = state.exception.detail,
				message   = state.exception.message,
				type      = &quot;any&quot;
			);
		} else {
			transaction action=&quot;commit&quot;;
		}
	}
}

// 2. Add a column to an existing table
function up() {
	var state = {};
	transaction {
		try {
			addColumn(table=&quot;users&quot;, columnType=&quot;string&quot;, columnName=&quot;avatarUrl&quot;, limit=500, allowNull=true);
		} catch (any e) {
			state.exception = e;
		}

		if (structKeyExists(state, &quot;exception&quot;)) {
			transaction action=&quot;rollback&quot;;
			throw(
				errorCode = &quot;1&quot;,
				detail    = state.exception.detail,
				message   = state.exception.message,
				type      = &quot;any&quot;
			);
		} else {
			transaction action=&quot;commit&quot;;
		}
	}
}

// 3. Run raw SQL and seed initial data in the same migration
function up() {
	var state = {};
	transaction {
		try {
			execute(&quot;ALTER TABLE products ADD COLUMN sku VARCHAR(50)&quot;);
			addRecord(table=&quot;settings&quot;, key=&quot;maintenance_mode&quot;, value=&quot;false&quot;);
		} catch (any e) {
			state.exception = e;
		}

		if (structKeyExists(state, &quot;exception&quot;)) {
			transaction action=&quot;rollback&quot;;
			throw(
				errorCode = &quot;1&quot;,
				detail    = state.exception.detail,
				message   = state.exception.message,
				type      = &quot;any&quot;
			);
		} else {
			transaction action=&quot;commit&quot;;
		}
	}
}
</code></pre>
