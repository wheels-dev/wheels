---
title: up()
description: "Defines the actions to migrate your database schema forward. It is called when applying a migration and is typically paired with the <code>down()</code> functio"
sidebar:
  label: up()
  order: 0
---

## Signature

`up()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

Defines the actions to migrate your database schema forward. It is called when applying a migration and is typically paired with the <code>down()</code> function, which rolls back the migration. All schema changes, such as creating tables, adding columns, or setting up indexes, should be placed inside <code>up()</code>. Wrapping your migration code in a transaction block ensures that changes are either fully applied or rolled back in case of errors. Only available in a migration CFC.




## Examples

<pre><code class='javascript'>function up() {
	transaction {
		try {
			// your code goes here
			t = createTable(name='myTable');
			t.timestamps();
			t.create();
		} catch (any e) {
			local.exception = e;
		}

		if (StructKeyExists(local, &quot;exception&quot;)) {
			transaction action=&quot;rollback&quot;;
			throw(errorCode=&quot;1&quot;, detail=local.exception.detail, message=local.exception.message, type=&quot;any&quot;);
		} else {
			transaction action=&quot;commit&quot;;
		}
	}
}
</code></pre>
