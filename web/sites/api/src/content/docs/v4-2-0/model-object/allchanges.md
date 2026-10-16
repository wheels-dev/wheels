---
title: allChanges()
description: "Returns a struct detailing all changes that have been made on the object but not yet saved to the database."
sidebar:
  label: allChanges()
  order: 0
---

## Signature

`allChanges()` — returns `struct`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns a struct detailing all changes that have been made on the object but not yet saved to the database.




## Examples

<pre><code class='javascript'>// 1. Get an object, change some properties, and inspect all changes before saving
member = model(&quot;member&quot;).findByKey(params.memberId);
member.firstName = params.newFirstName;
member.email = params.newEmail;
changes = member.allChanges();
// changes -&gt; {
//   firstName: { changedFrom: &quot;Jane&quot;, changedTo: &quot;Janet&quot; },
//   email:     { changedFrom: &quot;jane@example.com&quot;, changedTo: &quot;janet@example.com&quot; }
// }

// 2. Only call allChanges() when there are changes to process
post = model(&quot;post&quot;).findByKey(params.id);
post.title = params.title;
post.body = params.body;
if (post.hasChanged()) {
    changes = post.allChanges();
    for (prop in changes) {
        writeOutput(&quot;'#prop#' changed from '#changes[prop].changedFrom#' to '#changes[prop].changedTo#'&quot;);
    }
}

// 3. allChanges() returns an empty struct when nothing has changed
user = model(&quot;user&quot;).findByKey(params.userId);
changes = user.allChanges();
// changes -&gt; {} (empty struct — no unsaved changes)
</code></pre>
