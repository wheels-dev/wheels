---
title: allAssociationErrors()
description: "Gets all associated errors recursively"
sidebar:
  label: allAssociationErrors()
  order: 0
---

## Signature

`allAssociationErrors()` — returns `array`

**Available in:** `model`
**Category:** Error Functions

## Description

Gets all associated errors recursively



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `seenErrors` | `array` | no | `[runtime expression]` |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Collect all validation errors from associated objects on a post
post = model(&quot;Post&quot;).findOne(where=&quot;id=1&quot;, include=&quot;comments&quot;);
errors = post.allAssociationErrors();
// errors -&gt; array of error structs from associated comments (and their associations, recursively)
// Each struct contains keys: property, message, name

// 2. Use allErrors() with includeAssociations=true instead (preferred shorthand)
// allErrors() calls allAssociationErrors() internally when includeAssociations is true
post = model(&quot;Post&quot;).findOne(where=&quot;id=1&quot;, include=&quot;comments&quot;);
allErrors = post.allErrors(includeAssociations=true);
// allErrors -&gt; combined array of the post's own errors plus all associated errors

// 3. Check if any associated model has errors before saving
order = model(&quot;Order&quot;).findOne(where=&quot;id=1&quot;, include=&quot;lineItems&quot;);
associationErrors = order.allAssociationErrors();
if (arrayLen(associationErrors)) {
    writeOutput(&quot;One or more line items have validation errors.&quot;);
}
</code></pre>
