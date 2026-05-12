---
title: hasErrors()
description: "Checks whether a model object has any validation or other errors. It returns true if the object contains errors, or if a specific property or named error is pro"
sidebar:
  label: hasErrors()
  order: 0
---

## Signature

`hasErrors()` — returns `boolean`

**Available in:** `model`
**Category:** Error Functions

## Description

Checks whether a model object has any validation or other errors. It returns true if the object contains errors, or if a specific property or named error is provided, it checks only that subset. This is useful for validating objects before saving them to the database or displaying error messages to the user.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Name of the property to check if there are any errors set on. |
| `name` | `string` | no | — | Error name to check if there are any errors set with. |

</div>

## Examples

<pre><code class='javascript'>1. Get a post object
post = model(&quot;post&quot;).findByKey(params.postId);

// Check if the object has any errors
if (post.hasErrors()) {
    writeOutput(&quot;There are errors. Redirecting to the edit form...&quot;);
    redirectTo(action=&quot;edit&quot;, id=post.id);
}

2. Check if a specific property has errors
if (post.hasErrors(property=&quot;title&quot;)) {
    writeOutput(&quot;The title field contains errors.&quot;);
}

3. Check if a specific named error exists
if (post.hasErrors(name=&quot;requiredTitle&quot;)) {
    writeOutput(&quot;The post is missing a required title.&quot;);
}
</code></pre>
