---
title: propertyNames()
description: "Returns a list of all property names associated with a model. The list is ordered by the columns’ ordinal positions as they exist in the underlying database tab"
sidebar:
  label: propertyNames()
  order: 0
---

## Signature

`propertyNames()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns a list of all property names associated with a model. The list is ordered by the columns’ ordinal positions as they exist in the underlying database table. In addition to actual table columns, the list also includes any calculated properties defined through the property(), method, which may be derived from SQL expressions or mapped column names. This is useful when you need to dynamically work with all of a model’s attributes without hardcoding them, such as generating dynamic forms, building custom serializers, or inspecting ORM mappings.




## Examples

<pre><code class='javascript'>1. Get property names for the User model
propNames = model(&quot;user&quot;).propertyNames();
writeOutput(propNames);

2. Loop through property names
for (prop in listToArray(model(&quot;employee&quot;).propertyNames())) {
    writeOutput(&quot;Property: #prop#&lt;br&gt;&quot;);
}

3. Check if a property exists in the list
if (listFindNoCase(model(&quot;order&quot;).propertyNames(), &quot;totalAmount&quot;)) {
    writeOutput(&quot;Order model has a totalAmount property.&quot;);
}

4. Including calculated properties
// In the model configuration:
property(name=&quot;fullName&quot;, sql=&quot;firstName + ' ' + lastName&quot;);

// propertyNames() will now include &quot;fullName&quot;
writeOutput(model(&quot;user&quot;).propertyNames());
</code></pre>
