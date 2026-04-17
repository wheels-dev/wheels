---
title: setProperties()
description: "Allows you to set multiple properties of a model object at once. It is useful when you want to update a model with a structure (struct) of key/value pairs inste"
sidebar:
  label: setProperties()
  order: 0
---

## Signature

`setProperties()` — returns `void`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Allows you to set multiple properties of a model object at once. It is useful when you want to update a model with a structure (struct) of key/value pairs instead of assigning each property individually. The keys of the struct should match the property names of the model. You can also pass named arguments directly instead of a struct.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `properties` | `struct` | no | `[runtime expression]` | The properties you want to set on the object (can also be passed in as named arguments). |

## Examples

<pre><code class='javascript'>1. Using a struct (common scenario with form submission)
// Controller code: create new user
user = model(&quot;user&quot;).new();

// Set properties from a submitted form
user.setProperties(params.user);

// Save the updated user
user.save();

2. Using named arguments
user = model(&quot;user&quot;).new();

// Set properties directly using named arguments
user.setProperties(
    firstName=&quot;John&quot;,
    lastName=&quot;Doe&quot;,
    email=&quot;john.doe@example.com&quot;
);

// Save changes
user.save();

3. Using with validations
user = model(&quot;user&quot;).new();

// Set multiple properties, skipping one intentionally
user.setProperties({
    firstName = &quot;Jane&quot;,
    lastName = &quot;Smith&quot;
});

// Only save if validations pass
if(user.save()){
    writeOutput(&quot;User updated successfully!&quot;);
} else {
    writeDump(user.errors);
}</code></pre>
