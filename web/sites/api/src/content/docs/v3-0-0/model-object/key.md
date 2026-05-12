---
title: key()
description: "Returns the value of the primary key for the object."
sidebar:
  label: key()
  order: 0
---

## Signature

`key()` — returns `string`

**Available in:** `model`
**Category:** Miscellaneous Functions

## Description

Returns the value of the primary key for the object.
If you have a single primary key named id, then <code>someObject.key()</code> is functionally equivalent to <code>someObject.id</code>.
This method is more useful when you do dynamic programming and don't know the name of the primary key or when you use composite keys (in which case it's convenient to use this method to get a list of both key values returned).



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `$persisted` | `boolean` | no | `false` |  |
| `$returnTickCountWhenNew` | `boolean` | no | `false` |  |

</div>

## Examples

<pre><code class='javascript'>1. Single Primary Key
<!--- Assume Employee model has primary key `id` --->
employee = model(&quot;employee&quot;).findByKey(42);

&lt;cfoutput&gt;
Employee ID: #employee.key()# &lt;!--- Equivalent to employee.id ---&gt;
&lt;/cfoutput&gt;

2. Dynamic Key Retrieval
<!--- Useful when you don’t know the name of the primary key --->
anyEmployee = model(&quot;employee&quot;).findByKey(params.key);

primaryKey = anyEmployee.key();
writeOutput(&quot;Primary key value is: &quot; &amp; primaryKey);

3. Composite Primary Key
<!--- Assume Subscription model has composite keys: customerId, publicationId --->
subscription = model(&quot;subscription&quot;).findByKey(customerId=3, publicationId=7);

&lt;cfoutput&gt;
Composite Keys: #subscription.key()# &lt;!--- Outputs: &quot;3,7&quot; ---&gt;
&lt;/cfoutput&gt;

4. Use in Links or Forms
&lt;cfset employee = model(&quot;employee&quot;).findByKey(42)&gt;

&lt;!--- Generate a link with dynamic primary key ---&gt;
&lt;a href=&quot;#linkTo(action='edit', id=employee.key())#&quot;&gt;Edit Employee&lt;/a&gt;

&lt;!--- Hidden field for a form ---&gt;
#hiddenField(objectName=&quot;employee&quot;, property=&quot;id&quot;)#

5. Passing Keys in Nested Relationships
&lt;!--- Suppose a `bookAuthors` association exists ---&gt;
book = model(&quot;book&quot;).findByKey(15);

&lt;cfloop array=&quot;#book.bookAuthors#&quot; index=&quot;author&quot;&gt;
    &lt;cfoutput&gt;
        Author Key: #author.key()# &lt;br&gt;
    &lt;/cfoutput&gt;
&lt;/cfloop&gt;</code></pre>
