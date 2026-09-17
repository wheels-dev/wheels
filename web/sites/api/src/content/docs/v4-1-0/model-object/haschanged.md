---
title: hasChanged()
description: "Returns <code>true</code> if the specified property (or any if none was passed in) has been changed but not yet saved to the database."
sidebar:
  label: hasChanged()
  order: 0
---

## Signature

`hasChanged()` — returns `boolean`

**Available in:** `model`
**Category:** Change Functions

## Description

Returns <code>true</code> if the specified property (or any if none was passed in) has been changed but not yet saved to the database.
Will also return <code>true</code> if the object is new and no record for it exists in the database.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Name of property to check for change. |

</div>

## Examples

<pre><code class='javascript'>// 1. Check if a specific property has changed before saving
member = model(&quot;member&quot;).findByKey(params.memberId);
member.email = params.newEmail;

if (member.hasChanged(&quot;email&quot;)) {
    // Send a confirmation email before committing the change
    sendEmailChangeNotification(member);
}

// 2. Check if any property has changed (no argument)
user = model(&quot;User&quot;).findByKey(params.userId);
user.setProperties(params.user);

if (user.hasChanged()) {
    // At least one property differs from the persisted state
    user.save();
}

// 3. Use the dynamic shorthand — automatically generated per property
order = model(&quot;Order&quot;).findByKey(params.orderId);
order.status = &quot;shipped&quot;;

if (order.statusHasChanged()) {
    // Equivalent to: order.hasChanged(&quot;status&quot;)
    notifyCustomer(order);
}

// 4. New (unsaved) objects always return true — no persisted record exists yet
newPost = model(&quot;Post&quot;).new(title=&quot;Hello&quot;);
writeOutput(newPost.hasChanged()); // -&gt; true
</code></pre>
