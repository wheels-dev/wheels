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
