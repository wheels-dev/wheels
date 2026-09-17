---
title: includePartial()
description: "Includes the specified partial file in the view."
sidebar:
  label: includePartial()
  order: 0
---

## Signature

`includePartial()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

Includes the specified partial file in the view.
Similar to using <code>cfinclude</code> but with the ability to cache the result and use Wheels-specific file look-up.
By default, Wheels will look for the file in the current controller's view folder.
To include a file relative from the base <code>views</code> folder, you can start the path supplied to <code>partial</code> with a forward slash.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `partial` | `any` | yes | — | The name of the partial file to be used. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Do not include the partial filename's underscore and file extension. If you want to have Wheels display the partial for a single model object, array of model objects, or a query, pass a variable containing that data into this argument. |
| `group` | `string` | no | — | If passing a query result set for the partial argument, use this to specify the field to group the query by. A new query will be passed into the partial template for you to iterate over. |
| `cache` | `any` | no | — | Number of minutes to cache the content for. |
| `layout` | `string` | no | — | The layout to wrap the content in. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Pass `false` to not load a layout at all. |
| `spacer` | `string` | no | — | HTML or string to place between partials when called using a query. |
| `dataFunction` | `any` | no | `true` | Name of controller function to load data from. |
| `$prependWithUnderscore` | `boolean` | no | `true` |  |

</div>

## Examples

<pre><code class='javascript'>// 1. Include a partial from the current controller's view folder.
//    When in the &quot;sessions&quot; controller, Wheels looks for &quot;app/views/sessions/_login.cfm&quot;.
#includePartial(&quot;login&quot;)#

// 2. Include a partial relative to the root views folder using a leading slash.
//    Wheels looks for &quot;app/views/shared/_button.cfm&quot;.
#includePartial(partial=&quot;/shared/button&quot;)#

// 3. Pass a query to loop through records automatically.
//    Wheels loops through the result set and renders &quot;app/views/posts/_post.cfm&quot; for each row.
posts = model(&quot;Post&quot;).findAll();
#includePartial(posts)#

// 4. Override the template when rendering a query.
//    Provide the template path via partial and pass the query separately.
posts = model(&quot;Post&quot;).findAll();
#includePartial(partial=&quot;/shared/post&quot;, query=posts)#

// 5. Pass a single model object — Wheels renders the matching partial for its model type.
post = model(&quot;Post&quot;).findByKey(params.key);
#includePartial(post)#

// 6. Override the template when rendering a single model object.
post = model(&quot;Post&quot;).findByKey(params.key);
#includePartial(partial=&quot;/shared/post&quot;, object=post)#

// 7. Pass an array of model objects — Wheels iterates and renders the partial for each.
posts = model(&quot;Post&quot;).findAll(returnAs=&quot;objects&quot;);
#includePartial(posts)#

// 8. Override the template when rendering an array of model objects.
posts = model(&quot;Post&quot;).findAll(returnAs=&quot;objects&quot;);
#includePartial(partial=&quot;/shared/post&quot;, objects=posts)#

// 9. Cache the partial output for 30 minutes to reduce processing overhead.
#includePartial(partial=&quot;sidebar&quot;, cache=30)#

// 10. Group a query result set by a column before rendering.
//     Wheels splits the query into sub-queries grouped by &quot;categoryId&quot;
//     and passes each sub-query into &quot;app/views/products/_product.cfm&quot;.
products = model(&quot;Product&quot;).findAll(order=&quot;categoryId&quot;);
#includePartial(partial=&quot;product&quot;, query=products, group=&quot;categoryId&quot;)#

// 11. Insert a separator string between each rendered partial in a loop.
posts = model(&quot;Post&quot;).findAll();
#includePartial(partial=&quot;post&quot;, query=posts, spacer=&quot;&lt;hr&gt;&quot;)#
</code></pre>
