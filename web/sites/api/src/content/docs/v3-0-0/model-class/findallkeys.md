---
title: findAllKeys()
description: "The findAllKeys() function retrieves all primary key values for a model’s records and returns them as a list. By default, the values are separated with commas,"
sidebar:
  label: findAllKeys()
  order: 0
---

## Signature

`findAllKeys()` — returns `string`

**Available in:** `model`
**Category:** Read Functions

## Description

The findAllKeys() function retrieves all primary key values for a model’s records and returns them as a list. By default, the values are separated with commas, but you can change the delimiter with the delimiter argument or add single quotes around each value with the quoted argument. Since findAllKeys() accepts all arguments that findAll() does, you can also filter results with where, control ordering with order, or even include associations when filtering. This makes it useful when you need just the IDs of records without fetching full objects or rows.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `quoted` | `boolean` | no | `false` | Set to `true` to enclose each value in single-quotation marks. |
| `delimiter` | `string` | no | `,` | The delimiter character to separate the list items with. |

## Examples

<pre><code class='javascript'>1. Get all IDs for a model (basic usage):

artistIds = model(&quot;artist&quot;).findAllKeys();

Returns a comma-delimited list of all artist IDs.

2. Get active artist IDs with custom delimiter and quotes:

artistIds = model(&quot;artist&quot;).findAllKeys(quoted=true, delimiter=&quot;|&quot;, where=&quot;active=1&quot;);

Returns only active artist IDs, quoted and separated with |.

3. Limit results (top 10 user IDs):

userIds = model(&quot;user&quot;).findAllKeys(maxRows=10, order=&quot;createdAt DESC&quot;);

Returns the 10 most recently created user IDs.

4. Paginated IDs (books, second page):

bookIds = model(&quot;book&quot;).findAllKeys(page=2, perPage=20, order=&quot;title ASC&quot;);

Fetches IDs for books on page 2 (records 21–40), ordered alphabetically.

5. Grouped query with HAVING (order IDs by sales total):

orderIds = model(&quot;order&quot;).findAllKeys(group=&quot;productId&quot;, where=&quot;totalAmount &gt; 500&quot;);

Returns order IDs for products that generated more than $500 in sales.
</code></pre>
