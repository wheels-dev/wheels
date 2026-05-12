---
title: findLastOne()
description: "The findLastOne() function fetches the last record from the database table mapped to the model, ordered by the primary key value by default. You can override th"
sidebar:
  label: findLastOne()
  order: 0
---

## Signature

`findLastOne()` — returns `any`

**Available in:** `model`
**Category:** Read Functions

## Description

The findLastOne() function fetches the last record from the database table mapped to the model, ordered by the primary key value by default. You can override this ordering by passing a property name through the property argument (also aliased as properties). This is useful when you want to retrieve the "last" record based on something other than the primary key, such as the most recently created entry, the highest price, or the latest updated timestamp. The result is returned as a model object. This function was formerly known as findLast.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `property` | `string` | no | — | Name of the property to order by. This argument is also aliased as `properties`. |

</div>

## Examples

<pre><code class='javascript'>1. Get the last record by primary key (default behavior):

lastUser = model(&quot;user&quot;).findLastOne();

Fetches the user with the highest primary key value.

2. Get the last record alphabetically by name:

lastAuthor = model(&quot;author&quot;).findLastOne(property=&quot;lastName&quot;);

Fetches the author with the alphabetically last last name.

3. Get the most recently created record:

lastArticle = model(&quot;article&quot;).findLastOne(property=&quot;createdAt&quot;);

Fetches the article with the latest creation date.

4. Get the most expensive product:

priciestProduct = model(&quot;product&quot;).findLastOne(property=&quot;price&quot;);

Fetches the product with the highest price.

5. Use alias properties instead of property:

lastComment = model(&quot;comment&quot;).findLastOne(properties=&quot;createdAt&quot;);

Works the same as property — useful when you prefer the plural alias.
</code></pre>
