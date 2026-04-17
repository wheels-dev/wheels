---
title: down()
description: "down() defines the steps to revert a database migration. It’s executed when rolling back a migration, typically to undo the changes applied by the corresponding"
sidebar:
  label: down()
  order: 0
---

## Signature

`down()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

down() defines the steps to revert a database migration. It’s executed when rolling back a migration, typically to undo the changes applied by the corresponding up() function. Only available in a migration CFC




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
