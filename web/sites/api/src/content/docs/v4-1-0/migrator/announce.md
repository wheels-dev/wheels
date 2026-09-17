---
title: announce()
description: "Used internally by Migrator to provide feedback to the GUI and CLI about completed DB operations"
sidebar:
  label: announce()
  order: 0
---

## Signature

`announce()` — returns `any`

**Available in:** `migration`, `tabledefinition`
**Category:** Migration Functions

## Description

Used internally by Migrator to provide feedback to the GUI and CLI about completed DB operations
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `message` | `string` | yes | — |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Log a custom message during a migration's up() step
function up() {
	var state = {};
	transaction {
		try {
			t = createTable(name=&quot;articles&quot;, force=true);
			t.string(columnNames=&quot;title&quot;, allowNull=false);
			t.text(columnNames=&quot;body&quot;);
			t.timestamps();
			t.create();
			announce(&quot;Created articles table&quot;);
		} catch (any e) {
			state.exception = e;
		}

		if (StructKeyExists(state, &quot;exception&quot;)) {
			transaction action=&quot;rollback&quot;;
			throw(errorCode=&quot;1&quot;, detail=state.exception.detail, message=state.exception.message, type=&quot;any&quot;);
		} else {
			transaction action=&quot;commit&quot;;
		}
	}
}

// 2. Announce multiple steps to provide granular feedback
function up() {
	var state = {};
	transaction {
		try {
			addColumn(table=&quot;users&quot;, columnType=&quot;string&quot;, columnName=&quot;apiKey&quot;, limit=64, allowNull=true);
			announce(&quot;Added apiKey column to users&quot;);

			addIndex(table=&quot;users&quot;, columnNames=&quot;apiKey&quot;, unique=true);
			announce(&quot;Added unique index on users.apiKey&quot;);
		} catch (any e) {
			state.exception = e;
		}

		if (StructKeyExists(state, &quot;exception&quot;)) {
			transaction action=&quot;rollback&quot;;
			throw(errorCode=&quot;1&quot;, detail=state.exception.detail, message=state.exception.message, type=&quot;any&quot;);
		} else {
			transaction action=&quot;commit&quot;;
		}
	}
}
</code></pre>
