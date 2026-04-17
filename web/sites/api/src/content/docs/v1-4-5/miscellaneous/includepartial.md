---
title: includePartial()
description: "Includes the specified partial file in the view. Similar to using cfinclude but with the ability to cache the result and use Wheels-specific file look-up. By de"
sidebar:
  label: includePartial()
  order: 0
---

## Signature

`includePartial()` — returns `any`




## Description

Includes the specified partial file in the view. Similar to using cfinclude but with the ability to cache the result and use Wheels-specific file look-up. By default, CFWheels will look for the file in the current controller's view folder. To include a file relative from the base views folder, you can start the path supplied to name with a forward slash.

## Parameters

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `partial` | `any` | yes | — | The name of the partial file to be used. Prefix with a leading slash / if you need to build a path from the root views folder. Do not include the partial filename's underscore and file extension. If you want to have CFWheels display the partial for a single model object, array of model objects, or a query, pass a variable containing that data into this argument. |
| `group` | `string` | yes | — | If passing a query result set for the partial argument, use this to specify the field to group the query by. A new query will be passed into the partial template for you to iterate over. |
| `cache` | `any` | yes | — | Number of minutes to cache the content for. |
| `layout` | `string` | yes | — | The layout to wrap the content in. Prefix with a leading slash / if you need to build a path from the root views folder. Pass false to not load a layout at all. |
| `spacer` | `string` | yes | — | HTML or string to place between partials when called using a query. |
| `dataFunction` | `any` | yes | `true` | Name of controller function to load data from. |
| `query` | `query` | yes | — | If you want to have CFWheels display the partial for each record in a query record set but want to override the name of the file referenced, provide the template file name for partial and pass the query as a separate query argument. |
| `object` | `component` | yes | — | If you want to have CFWheels display the partial for a model object but want to override the name of the file referenced, provide the template file name for partial and pass the model object as a separate object argument. |
| `objects` | `array` | yes | — | If you want to have CFWheels display the partial for each model object in an array but want to override the name of the file referenced, provide the template name for partial and pass the query as a separate objects argument. |

## Examples

<pre>&lt;cfoutput&gt; &lt;!--- If we're in the &quot;sessions&quot; controller, CFWheels will include the file &quot;views/sessions/_login.cfm&quot;. ---&gt; #includePartial(&quot;login&quot;)# &lt;!--- CFWheels will include the file &quot;views/shared/_button.cfm&quot;. ---&gt; #includePartial(partial=&quot;/shared/button&quot;)# &lt;!--- If we're in the &quot;posts&quot; controller and the &quot;posts&quot; variable includes a query result set, CFWheels will loop through the record set and include the file &quot;views/posts/_post.cfm&quot; for each record. ---&gt; &lt;cfset posts = model(&quot;post&quot;).findAll()&gt; #includePartial(posts)# &lt;!--- We can also override the template file loaded for the example above. ---&gt; #includePartial(partial=&quot;/shared/post&quot;, query=posts)# &lt;!--- The same works when passing a model instance. ---&gt; &lt;cfset post = model(&quot;post&quot;).findByKey(params.key)&gt; #includePartial(post)# #includePartial(partial=&quot;/shared/post&quot;, object=post)# &lt;!--- The same works when passing an array of model objects. ---&gt; &lt;cfset posts = model(&quot;post&quot;).findAll(returnAs=&quot;objects&quot;)&gt; #includePartial(posts)# #includePartial(partial=&quot;/shared/post&quot;, objects=posts)# &lt;/cfoutput&gt;</pre>
