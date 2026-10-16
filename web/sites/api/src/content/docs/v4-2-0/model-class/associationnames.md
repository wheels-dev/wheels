---
title: associationNames()
description: "Returns a list of association names defined on this model."
sidebar:
  label: associationNames()
  order: 0
---

## Signature

`associationNames()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a list of association names defined on this model.




## Examples

<pre><code class='javascript'>// 1. Get all association names defined on a model
names = model(&quot;User&quot;).associationNames();
// names -&gt; &quot;profile,posts,comments&quot;

// 2. Check whether a specific association exists on the model
if (listFindNoCase(model(&quot;Post&quot;).associationNames(), &quot;comments&quot;)) {
    // the Post model has a &quot;comments&quot; association
}

// 3. Iterate over each association name
for (assocName in listToArray(model(&quot;Order&quot;).associationNames())) {
    writeOutput(assocName);
}
</code></pre>
