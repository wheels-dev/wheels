---
title: changedProperties()
description: "Returns a list of the object properties that have been changed but not yet saved to the database."
sidebar:
  label: changedProperties()
  order: 0
---

## Signature

`changedProperties()` — returns `string`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns a list of the object properties that have been changed but not yet saved to the database.




## Examples

<pre><code class='javascript'>// 1. Find a member, change some properties, then inspect which ones have changed
member = model(&quot;member&quot;).findByKey(params.memberId);
member.firstName = params.newFirstName;
member.email = params.newEmail;
changed = member.changedProperties();
// changed -&gt; &quot;firstName,email&quot;

// 2. Only save when there are actually unsaved changes
user = model(&quot;User&quot;).findByKey(params.userId);
user.lastName = params.lastName;
if (Len(user.changedProperties())) {
    user.save();
}

// 3. Use changedProperties() alongside changedFrom() to build an audit log entry
post = model(&quot;Post&quot;).findByKey(params.postId);
post.title = params.title;
post.body = params.body;
changedList = post.changedProperties();
for (prop in ListToArray(changedList)) {
    writeOutput(&quot;Property '#prop#' was '#post.changedFrom(prop)#', now '#post[prop]#'.&quot;);
}
</code></pre>
