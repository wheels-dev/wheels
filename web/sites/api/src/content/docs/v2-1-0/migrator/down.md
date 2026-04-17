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

<pre><code class='javascript'>function down() {
	transaction {
		try {
			// your code goes here
			dropTable('myTable');
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
