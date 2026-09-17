---
title: associationInfo()
description: "Returns a struct containing all association definitions for this model."
sidebar:
  label: associationInfo()
  order: 0
---

## Signature

`associationInfo()` — returns `struct`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a struct containing all association definitions for this model.
Each key is the association name, and the value is a struct with association metadata
including <code>type</code> (belongsTo, hasMany, hasOne), <code>modelName</code>, <code>foreignKey</code>, <code>joinKey</code>, and <code>dependent</code>.




## Examples

<pre><code class='javascript'>// 1. Get all association definitions for a model and inspect them
info = model(&quot;post&quot;).associationInfo();
// info is a struct where each key is an association name, e.g.:
// info.comments.type        -&gt; &quot;hasMany&quot;
// info.comments.modelName   -&gt; &quot;Comment&quot;
// info.comments.foreignKey  -&gt; &quot;postId&quot;
// info.comments.dependent   -&gt; &quot;delete&quot;
// info.author.type          -&gt; &quot;belongsTo&quot;
// info.author.modelName     -&gt; &quot;Author&quot;

// 2. Check whether a specific association is defined on the model
info = model(&quot;user&quot;).associationInfo();
if (structKeyExists(info, &quot;profile&quot;)) {
    writeOutput(&quot;User has a profile association of type: &quot; &amp; info.profile.type);
}

// 3. Iterate over all associations to build a summary
info = model(&quot;article&quot;).associationInfo();
for (assocName in info) {
    writeOutput(assocName &amp; &quot; -&gt; &quot; &amp; info[assocName].type &amp; &quot; &quot; &amp; info[assocName].modelName);
}
</code></pre>
