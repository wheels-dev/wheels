---
title: down()
description: "Migrates down: will be executed when migrating your schema backward"
sidebar:
  label: down()
  order: 0
---

## Signature

`down()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Migrates down: will be executed when migrating your schema backward
Along with up(), these are the two main functions in any migration file
Only available in a migration CFC




## Examples

<pre><code class='javascript'>// 1. Reverse a table creation by dropping the table
// Called automatically when rolling back this migration
function down() {
	var state = {};
	transaction {
		try {
			dropTable(&quot;employees&quot;);
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

// 2. Reverse an addColumn() call by removing the column
function down() {
	var state = {};
	transaction {
		try {
			removeColumn(table=&quot;users&quot;, columnName=&quot;biography&quot;);
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

// 3. Paired up() and down() inside a full migration component
component extends=&quot;[extends]&quot; hint=&quot;Add status column to orders&quot; {

	function up() {
		var state = {};
		transaction {
			try {
				addColumn(table=&quot;orders&quot;, columnType=&quot;string&quot;, columnName=&quot;status&quot;, limit=50, default=&quot;pending&quot;);
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

	function down() {
		var state = {};
		transaction {
			try {
				removeColumn(table=&quot;orders&quot;, columnName=&quot;status&quot;);
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

}
</code></pre>
