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
Similar to using <code>cfinclude</code> but with the ability to cache the result and use CFWheels-specific file look-up.
By default, CFWheels will look for the file in the current controller's view folder.
To include a file relative from the base <code>views</code> folder, you can start the path supplied to <code>partial</code> with a forward slash.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `partial` | `any` | yes | — | The name of the partial file to be used. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Do not include the partial filename's underscore and file extension. If you want to have CFWheels display the partial for a single model object, array of model objects, or a query, pass a variable containing that data into this argument. |
| `group` | `string` | no | — | If passing a query result set for the partial argument, use this to specify the field to group the query by. A new query will be passed into the partial template for you to iterate over. |
| `cache` | `any` | no | — | Number of minutes to cache the content for. |
| `layout` | `string` | no | — | The layout to wrap the content in. Prefix with a leading slash (`/`) if you need to build a path from the root `views` folder. Pass `false` to not load a layout at all. |
| `spacer` | `string` | no | — | HTML or string to place between partials when called using a query. |
| `dataFunction` | `any` | no | `true` | Name of controller function to load data from. |
| `$prependWithUnderscore` | `boolean` | no | `true` |  |

</div>

## Examples

<pre><code class='javascript'>
// If we're in the &quot;sessions&quot; controller, CFWheels will include the file &quot;views/sessions/_login.cfm&quot;.  
#includePartial(&quot;login&quot;)# 

// CFWheels will include the file &quot;views/shared/_button.cfm&quot;.  
#includePartial(partial=&quot;/shared/button&quot;)# 

// If we're in the &quot;posts&quot; controller and the &quot;posts&quot; variable includes a query result set, CFWheels will loop through the record set and include the file &quot;views/posts/_post.cfm&quot; for each record.  
&lt;cfset posts = model(&quot;post&quot;).findAll()&gt; 
#includePartial(posts)# 

// We can also override the template file loaded for the example above.  
#includePartial(partial=&quot;/shared/post&quot;, query=posts)# 

// The same works when passing a model instance.  
&lt;cfset post = model(&quot;post&quot;).findByKey(params.key)&gt; #includePartial(post)# 
#includePartial(partial=&quot;/shared/post&quot;, object=post)# 

// The same works when passing an array of model objects.  
&lt;cfset posts = model(&quot;post&quot;).findAll(returnAs=&quot;objects&quot;)&gt; 
#includePartial(posts)# 
#includePartial(partial=&quot;/shared/post&quot;, objects=posts)# 
&lt;/cfoutput&gt;

</code></pre>
