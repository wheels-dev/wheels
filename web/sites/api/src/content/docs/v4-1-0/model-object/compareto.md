---
title: compareTo()
description: "Pass in another model object to see if the two objects are the same."
sidebar:
  label: compareTo()
  order: 0
---

## Signature

`compareTo()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Pass in another model object to see if the two objects are the same.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `object` | `component` | yes | — |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Check if two model objects are the same instance
user1 = model(&quot;User&quot;).findByKey(1);
user2 = model(&quot;User&quot;).findByKey(1);
user3 = user1;

isSame = user1.compareTo(user2);
// isSame -&gt; false (two separate fetches produce distinct instances)

isSame = user1.compareTo(user3);
// isSame -&gt; true (user3 is the same object reference as user1)

// 2. Guard against processing the same object twice in a loop
users = model(&quot;User&quot;).findAll(returnAs=&quot;objects&quot;);
currentUser = model(&quot;User&quot;).findByKey(session.userId);

for (u in users) {
    if (!u.compareTo(currentUser)) {
        // process all users except the currently logged-in one
        sendNotification(u);
    }
}
</code></pre>
