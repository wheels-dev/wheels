---
title: save()
description: "Saves the current model object to the database, with Wheels automatically determining whether to perform an INSERT for new objects or an UPDATE for existing one"
sidebar:
  label: save()
  order: 0
---

## Signature

`save()` — returns `boolean`

**Available in:** `model`
**Category:** CRUD Functions

## Description

Saves the current model object to the database, with Wheels automatically determining whether to perform an INSERT for new objects or an UPDATE for existing ones. It returns true if the object was successfully saved, and false if the object failed validation or could not be saved. By default, save() also respects callbacks, validations, and parameterization, though these behaviors can be customized through optional arguments.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `parameterize` | `any` | no | `true` | Set to `true` to use `cfqueryparam` on all columns, or pass in a list of property names to use `cfqueryparam` on those only. |
| `reload` | `boolean` | no | `false` | Set to `true` to force Wheels to query the database even though an identical query for this model may have been run in the same request. (The default in Wheels is to get the second query from the model's request-level cache.) |
| `validate` | `boolean` | no | `true` | Set to `false` to skip validations for this operation. |
| `transaction` | `string` | no | `[runtime expression]` | Set this to `commit` to update the database, `rollback` to run all the database queries but not commit them, or `none` to skip transaction handling altogether. |
| `callbacks` | `boolean` | no | `true` | Set to `false` to disable callbacks for this method. |

## Examples

<pre><code class='javascript'>1. Basic Save (Automatic INSERT/UPDATE)

&lt;cfscript&gt;
user = model(&quot;user&quot;).new();
user.firstName = &quot;Alice&quot;;
user.lastName = &quot;Smith&quot;;
user.email = &quot;alice@example.com&quot;;

if(user.save()){
    writeOutput(&quot;User saved successfully!&quot;);
} else {
    writeOutput(&quot;Error saving user. Please check validations.&quot;);
}
&lt;/cfscript&gt;

2. Save Without Validations

&lt;cfscript&gt;
user = model(&quot;user&quot;).findByKey(1);
user.firstName = &quot;&quot;; // Normally fails validation

// Save without running validations
user.save(validate=false);
&lt;/cfscript&gt;

3. Save Using Specific cfqueryparam Columns

&lt;cfscript&gt;
user = model(&quot;user&quot;).new();
user.firstName = &quot;Bob&quot;;
user.lastName = &quot;Jones&quot;;
user.email = &quot;bob@example.com&quot;;

// Only parameterize the `email` field
user.save(parameterize=&quot;email&quot;);
&lt;/cfscript&gt;

4. Save Within a Transaction

&lt;cfscript&gt;
user = model(&quot;user&quot;).new();
user.firstName = &quot;Charlie&quot;;
user.lastName = &quot;Brown&quot;;
user.email = &quot;charlie@example.com&quot;;

// Attempt to save, but roll back instead of committing
user.save(transaction=&quot;rollback&quot;);
&lt;/cfscript&gt;

5. Save and Handle Callbacks Manually

&lt;cfscript&gt;
user = model(&quot;user&quot;).new();
user.firstName = &quot;Dana&quot;;
user.lastName = &quot;White&quot;;
user.email = &quot;dana@example.com&quot;;

// Save without triggering beforeSave/afterSave callbacks
user.save(callbacks=false);
&lt;/cfscript&gt;
</code></pre>
