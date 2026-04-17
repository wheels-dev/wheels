---
title: findFirst()
description: "The findFirst() function fetches the first record from the database table mapped to the model, ordered by the primary key value by default. You can customize th"
sidebar:
  label: findFirst()
  order: 0
---

## Signature

`findFirst()` — returns `any`

**Available in:** `model`
**Category:** Read Functions

## Description

The findFirst() function fetches the first record from the database table mapped to the model, ordered by the primary key value by default. You can customize the ordering by passing a property name through the property argument, which is also aliased as properties. This makes it useful when you want the "first" record based on a specific field (e.g., earliest created date, alphabetically first name, lowest price, etc.). The result is returned as a model object.



## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | `[runtime expression]` | Name of the property to order by. This argument is also aliased as `properties`. |
| `$sort` | `string` | no | `ASC` |  |

## Examples

<pre><code class='javascript'>1. Get the first record by primary key (default behavior):

firstUser = model(&quot;user&quot;).findFirst();

Fetches the user with the lowest primary key value.

2. Get the first record alphabetically by name:

firstAuthor = model(&quot;author&quot;).findFirst(property=&quot;lastName&quot;);

Fetches the author with the alphabetically first last name.

3. Get the earliest created record (using a timestamp column):

firstArticle = model(&quot;article&quot;).findFirst(property=&quot;createdAt&quot;);

Fetches the oldest article based on creation date.

4. Get the cheapest product:

cheapestProduct = model(&quot;product&quot;).findFirst(property=&quot;price&quot;);

Fetches the product with the lowest price.

5. Use alias properties instead of property:

firstComment = model(&quot;comment&quot;).findFirst(properties=&quot;createdAt&quot;);

Works the same as property — useful when you prefer the plural alias.
</code></pre>
