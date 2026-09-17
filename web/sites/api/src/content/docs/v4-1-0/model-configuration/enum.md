---
title: enum()
description: "Maps a property to a set of named values (like Rails enums)."
sidebar:
  label: enum()
  order: 0
---

## Signature

`enum()` — returns `void`

**Available in:** `model`
**Category:** Enum Functions

## Description

Maps a property to a set of named values (like Rails enums).
Generates boolean checker methods (<code>is<Value>()</code>), scopes for each value,
and validates that the property value is one of the allowed values.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | The name of the model property to map as an enum. |
| `values` | `any` | yes | — | Either a comma-delimited list of string values (e.g. `"draft,published,archived"`) or a struct mapping names to stored values (e.g. `{low: 0, medium: 1, high: 2}`). |

</div>

## Examples

<pre><code class='javascript'>// 1. Map a `status` property to a comma-delimited list of allowed string values.
//    Wheels auto-validates that `status` is one of the listed values,
//    creates `isDraft()`, `isPublished()`, and `isArchived()` checker methods,
//    and registers `draft()`, `published()`, and `archived()` query scopes.
component extends=&quot;Model&quot; {
	function config() {
		enum(property=&quot;status&quot;, values=&quot;draft,published,archived&quot;);
	}
}

// 2. Map a `priority` property using a struct so that the stored database value
//    differs from the human-readable name (0, 1, 2 are stored; low/medium/high are the names).
//    Generated methods: `isLow()`, `isMedium()`, `isHigh()`.
//    Generated scopes:  `model(&quot;Task&quot;).low()`, `model(&quot;Task&quot;).medium()`, `model(&quot;Task&quot;).high()`.
component extends=&quot;Model&quot; {
	function config() {
		enum(property=&quot;priority&quot;, values={low: 0, medium: 1, high: 2});
	}
}

// 3. Using the generated checker methods and scopes at runtime.
//    `isPublished()` returns true/false; `published()` scopes a finder to that status.
post = model(&quot;Post&quot;).findByKey(key=42);
if (post.isPublished()) {
	writeOutput(&quot;This post is live.&quot;);
}

// Find all published posts using the auto-generated scope.
publishedPosts = model(&quot;Post&quot;).published().findAll();
</code></pre>
