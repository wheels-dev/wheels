---
title: propertyIsBlank()
description: "Returns <code>true</code> if the specified property doesn't exist on the model or is an empty string."
sidebar:
  label: propertyIsBlank()
  order: 0
---

## Signature

`propertyIsBlank()` — returns `boolean`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns <code>true</code> if the specified property doesn't exist on the model or is an empty string.
This method is the inverse of <code>propertyIsPresent()</code>.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | yes | — | Name of property to inspect. |

</div>

## Examples

<pre><code class='javascript'>// 1. Check if a property is blank before sending a notification
user = model(&quot;User&quot;).findByKey(params.userId);
if (user.propertyIsBlank(&quot;email&quot;)) {
    flashInsert(error=&quot;Please provide an email address before continuing.&quot;);
}

// 2. Conditionally set a default value when a property is blank
product = model(&quot;Product&quot;).findByKey(params.id);
if (product.propertyIsBlank(&quot;description&quot;)) {
    product.description = &quot;No description available.&quot;;
    product.save();
}

// 3. Use propertyIsBlank alongside its inverse propertyIsPresent for branching logic
post = model(&quot;Post&quot;).findByKey(params.postId);
if (post.propertyIsBlank(&quot;publishedAt&quot;)) {
    // post has never been published
    writeOutput(&quot;Draft&quot;);
} else {
    // propertyIsPresent(&quot;publishedAt&quot;) would return true here
    writeOutput(&quot;Published on #post.publishedAt#&quot;);
}
</code></pre>
