---
title: enumInfo()
description: "Returns a struct containing all enum definitions for this model."
sidebar:
  label: enumInfo()
  order: 0
---

## Signature

`enumInfo()` — returns `struct`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a struct containing all enum definitions for this model.
Each key is the property name, and the value contains <code>values</code> (name-to-stored-value mapping) and <code>names</code> (list of enum names).




## Examples

<pre><code class='javascript'>// 1. Inspect all enum definitions on the Order model
info = model(&quot;Order&quot;).enumInfo();
// info -&gt; {
//   status: {
//     property: &quot;status&quot;,
//     names: &quot;draft,published,archived&quot;,
//     values: {draft: &quot;draft&quot;, published: &quot;published&quot;, archived: &quot;archived&quot;}
//   }
// }

// 2. List all enum-mapped properties
info = model(&quot;Order&quot;).enumInfo();
for (propName in info) {
    writeOutput(propName &amp; &quot;: &quot; &amp; info[propName].names);
}
// status: draft,published,archived
// priority: low,medium,high

// 3. Use enum metadata to build a select list for a form
info = model(&quot;Order&quot;).enumInfo();
statusEnum = info[&quot;status&quot;];
for (enumName in listToArray(statusEnum.names)) {
    storedValue = statusEnum.values[enumName];
    writeOutput(enumName &amp; &quot; -&gt; &quot; &amp; storedValue);
}
// draft -&gt; draft
// published -&gt; published
// archived -&gt; archived
</code></pre>
