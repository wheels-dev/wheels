---
title: dropView()
description: "drops a view from the database"
sidebar:
  label: dropView()
  order: 0
---

## Signature

`dropView()` — returns `void`

**Available in:** `migration`
**Category:** Migration Functions

## Description

drops a view from the database
Only available in a migration CFC



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `name` | `string` | yes | — | Name of the view to drop |

</div>

## Examples

<pre><code class='javascript'>// 1. Drop a view in the down() migration (reversing a createView in up())
component extends=&quot;wheels.migrator.Migration&quot; hint=&quot;Add active users view&quot; {

	function up() {
		createView(name=&quot;activeUsers&quot;)
			.selectStatement(sql=&quot;SELECT id, firstName, lastName, email FROM users WHERE deletedAt IS NULL&quot;)
			.create();
	}

	function down() {
		dropView(name=&quot;activeUsers&quot;);
	}

}

// 2. Drop multiple views in a single down() migration
component extends=&quot;wheels.migrator.Migration&quot; hint=&quot;Add reporting views&quot; {

	function up() {
		createView(name=&quot;publishedArticles&quot;)
			.selectStatement(sql=&quot;SELECT id, title, authorId, publishedAt FROM articles WHERE publishedAt IS NOT NULL&quot;)
			.create();

		createView(name=&quot;activeAuthors&quot;)
			.selectStatement(sql=&quot;SELECT id, firstName, lastName FROM users WHERE deletedAt IS NULL&quot;)
			.create();
	}

	function down() {
		dropView(name=&quot;publishedArticles&quot;);
		dropView(name=&quot;activeAuthors&quot;);
	}

}
</code></pre>
