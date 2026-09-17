---
title: onMissingMethod()
description: "This method is not designed to be called directly from your code, but provides functionality for dynamic finders such as <code>findOneByEmail()</code>"
sidebar:
  label: onMissingMethod()
  order: 0
---

## Signature

`onMissingMethod()` — returns `any`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

This method is not designed to be called directly from your code, but provides functionality for dynamic finders such as <code>findOneByEmail()</code>



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `missingMethodName` | `string` | yes | — |  |
| `missingMethodArguments` | `struct` | yes | — |  |

</div>

## Examples

<pre><code class='javascript'>// Note: onMissingMethod() is not called directly. It is the CFML hook that
// powers Wheels' dynamic model methods. The examples below show what you
// call in your code — Wheels intercepts each one automatically.

// 1. Dynamic finder: findOneBy&lt;Property&gt;
// Finds the first user whose email matches the given value.
user = model(&quot;User&quot;).findOneByEmail(&quot;jane@example.com&quot;);

// 2. Dynamic finder: findAllBy&lt;Property&gt;
// Finds all posts with the given status.
posts = model(&quot;Post&quot;).findAllByStatus(&quot;published&quot;);

// 3. Dynamic finder across multiple properties joined by &quot;And&quot;
// Finds a single order matching both customerId and status.
order = model(&quot;Order&quot;).findOneByCustomerIdAndStatus(42, &quot;pending&quot;);

// 4. Find or create by property
// Returns an existing tag with the name &quot;cfml&quot;, or creates one if none exists.
tag = model(&quot;Tag&quot;).findOrCreateByName(&quot;cfml&quot;);

// 5. Association helpers generated for hasMany (comments on a post)
post = model(&quot;Post&quot;).findByKey(1);
// Retrieve all associated comments
comments = post.comments();
// Count associated comments
total = post.commentCount();
// Create a new associated comment (foreign key set automatically)
post.createComment(body=&quot;Great post!&quot;);

// 6. Property change helpers
user = model(&quot;User&quot;).findByKey(1);
user.email = &quot;new@example.com&quot;;
// Check whether a specific property has changed since the record was loaded
changed = user.emailHasChanged();
// Get the original value before the change
original = user.emailChangedFrom();

// 7. Enum boolean helpers (requires enum() declaration in model config)
// component Post extends=&quot;Model&quot; { function config() { enum(property=&quot;status&quot;, values=&quot;draft,published,archived&quot;); } }
post = model(&quot;Post&quot;).findByKey(1);
writeOutput(post.isPublished()); // true or false
writeOutput(post.isDraft());     // true or false
</code></pre>
