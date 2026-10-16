---
title: classInfo()
description: "Returns a comprehensive struct of all model metadata suitable for code generation and introspection tools."
sidebar:
  label: classInfo()
  order: 0
---

## Signature

`classInfo()` — returns `struct`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a comprehensive struct of all model metadata suitable for code generation and introspection tools.
Includes model name, table name, primary keys, properties, associations, validations, enums, scopes, and callbacks.




## Examples

<pre><code class='javascript'>// 1. Inspect all metadata for the User model
info = model(&quot;User&quot;).classInfo();
// info.modelName             -&gt; &quot;User&quot;
// info.tableName             -&gt; &quot;users&quot;
// info.primaryKeys           -&gt; &quot;id&quot;
// info.propertyNames         -&gt; &quot;id,firstName,lastName,email,createdAt,updatedAt&quot;
// info.properties            -&gt; struct of column/type metadata keyed by property name
// info.calculatedProperties  -&gt; struct of SQL-expression properties keyed by property name
// info.associations          -&gt; struct of association definitions (belongsTo, hasMany, etc.)
// info.validations           -&gt; struct keyed by trigger (onSave, onCreate, onUpdate) with arrays of rules
// info.enums                 -&gt; struct of enum definitions keyed by property name
// info.scopes                -&gt; struct of named scope definitions
// info.callbacks             -&gt; struct of callback arrays keyed by callback type (beforeSave, afterCreate, etc.)
// info.softDeletion          -&gt; false (true when the model has a deletedAt column)

// 2. List all association names and their types
info = model(&quot;Article&quot;).classInfo();

for (assocName in info.associations) {
    assoc = info.associations[assocName];
    writeOutput(assocName &amp; &quot; (&quot; &amp; assoc.type &amp; &quot;)&quot;);
}

// 3. Check soft-deletion and enumerate registered callbacks
info = model(&quot;Post&quot;).classInfo();

if (info.softDeletion) {
    writeOutput(&quot;Post uses soft deletion.&quot;);
}

for (callbackType in info.callbacks) {
    methods = info.callbacks[callbackType];
    writeOutput(callbackType &amp; &quot;: &quot; &amp; arrayToList(methods));
}

// 4. Inspect calculated properties defined on the model
info = model(&quot;Order&quot;).classInfo();

for (propName in info.calculatedProperties) {
    calcProp = info.calculatedProperties[propName];
    writeOutput(propName &amp; &quot; =&gt; &quot; &amp; calcProp.sql);
}
</code></pre>
