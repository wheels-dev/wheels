---
title: flashInsert()
description: "Inserts a new key / value into the Flash."
sidebar:
  label: flashInsert()
  order: 0
---

## Signature

`flashInsert()` — returns `void`

**Available in:** `controller`
**Category:** Flash Functions

## Description

Inserts a new key / value into the Flash.




## Examples

<pre><code class='javascript'>// 1. Insert a single key / value into the Flash
flashInsert(notice=&quot;Your profile has been updated.&quot;);

// 2. Insert multiple keys at once
flashInsert(success=&quot;Account created.&quot;, hint=&quot;Check your email to confirm.&quot;);

// 3. Read back a Flash value in the next action or view
// (After a redirect, in the destination action or its view:)
msg = flash(&quot;notice&quot;);
// msg -&gt; &quot;Your profile has been updated.&quot;
</code></pre>
