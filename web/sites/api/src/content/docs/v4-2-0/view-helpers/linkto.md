---
title: linkTo()
description: "Creates a link to another page in your application."
sidebar:
  label: linkTo()
  order: 0
---

## Signature

`linkTo()` — returns `string`

**Available in:** `controller`
**Category:** Link Functions

## Description

Creates a link to another page in your application.
Pass in the name of a route to use your configured routes or a controller/action/key combination.
Note: Pass any additional arguments like class, rel, and id, and the generated tag will also include those values as HTML attributes.



## Parameters

<div class="wd-params-table">

| Name | Type | Required | Default | Description |
| ---- | ---- | -------- | ------- | ----------- |
| `text` | `string` | no | — | The text content of the link. |
| `route` | `string` | no | — | Name of a route that you have configured in config/routes.cfm. |
| `controller` | `string` | no | — | Name of the controller to include in the URL. |
| `action` | `string` | no | — | Name of the action to include in the URL. |
| `key` | `any` | no | — | Key(s) to include in the URL. |
| `params` | `string` | no | — | Any additional parameters to be set in the query string (example: wheels=cool&x=y). Please note that Wheels uses the & and = characters to split the parameters and encode them properly for you. However, if you need to pass in & or = as part of the value, then you need to encode them (and only them), example: a=cats%26dogs%3Dtrouble!&b=1. |
| `anchor` | `string` | no | — | Sets an anchor name to be appended to the path. |
| `onlyPath` | `boolean` | no | `true` | If true, returns only the relative URL (no protocol, host name or port). |
| `host` | `string` | no | — | Set this to override the current host. |
| `protocol` | `string` | no | — | Set this to override the current protocol. |
| `port` | `numeric` | no | `0` | Set this to override the current port number. |
| `href` | `string` | no | — | Pass a link to an external site here if you want to bypass the Wheels routing system altogether and link to an external URL. |
| `encode` | `any` | no | `true` | Use this argument to decide whether the output of the function should be encoded in order to prevent Cross Site Scripting (XSS) attacks. Set it to `true` to encode all relevant output for the specific HTML element in question (e.g. tag content, attribute values, and URLs). For HTML elements that have both tag content and attribute values you can set this argument to `attributes` to only encode attribute values and not tag content. |
| `sanitizeHref` | `boolean` | no | `false` | When true, blank out caller-supplied `javascript:` / `data:` hrefs. Default false (B3: default deny is a public-behavior change). |

</div>

## Examples

<pre><code class='javascript'>// 1. Link to a controller/action pair
writeOutput(linkTo(text=&quot;Log Out&quot;, controller=&quot;account&quot;, action=&quot;logout&quot;));
// -&gt; &lt;a href=&quot;/account/logout&quot;&gt;Log Out&lt;/a&gt;

// 2. Omit the controller when linking within the same controller
// (CFWheels uses the current controller automatically)
writeOutput(linkTo(text=&quot;Log Out&quot;, action=&quot;logout&quot;));
// -&gt; &lt;a href=&quot;/account/logout&quot;&gt;Log Out&lt;/a&gt;

// 3. Link to a specific record using a key
writeOutput(linkTo(text=&quot;View Post&quot;, controller=&quot;blog&quot;, action=&quot;post&quot;, key=99));
// -&gt; &lt;a href=&quot;/blog/post/99&quot;&gt;View Post&lt;/a&gt;

// 4. Pass extra query string parameters
writeOutput(linkTo(text=&quot;View Settings&quot;, action=&quot;settings&quot;, params=&quot;show=all&amp;sort=asc&quot;));
// -&gt; &lt;a href=&quot;/account/settings?show=all&amp;amp;sort=asc&quot;&gt;View Settings&lt;/a&gt;

// 5. Use a named route (configured in app/config/routes.cfm)
writeOutput(linkTo(text=&quot;Joe's Profile&quot;, route=&quot;userProfile&quot;, userName=&quot;joe&quot;));
// -&gt; &lt;a href=&quot;/user/joe&quot;&gt;Joe's Profile&lt;/a&gt;

// 6. Link to an external URL, bypassing the routing system
writeOutput(linkTo(text=&quot;ColdFusion on Wheels&quot;, href=&quot;https://cfwheels.org/&quot;));
// -&gt; &lt;a href=&quot;https://cfwheels.org/&quot;&gt;ColdFusion on Wheels&lt;/a&gt;

// 7. Add HTML attributes (class, id, rel, etc.) via extra arguments
writeOutput(linkTo(text=&quot;Delete Post&quot;, action=&quot;delete&quot;, key=99, class=&quot;delete&quot;, id=&quot;delete-99&quot;));
// -&gt; &lt;a class=&quot;delete&quot; href=&quot;/blog/delete/99&quot; id=&quot;delete-99&quot;&gt;Delete Post&lt;/a&gt;

// 8. Include icon markup in link text; use encode=&quot;attributes&quot; to encode
//    only attribute values and leave the tag content (the icon HTML) untouched
writeOutput(linkTo(text=&quot;&lt;i class='fa fa-trash'&gt;&lt;/i&gt; Delete Post&quot;, encode=&quot;attributes&quot;, action=&quot;delete&quot;, key=99));
// -&gt; &lt;a href=&quot;/blog/delete/99&quot;&gt;&lt;i class='fa fa-trash'&gt;&lt;/i&gt; Delete Post&lt;/a&gt;

// 9. Build an absolute URL by turning off onlyPath and setting a protocol/host
writeOutput(linkTo(text=&quot;Home&quot;, action=&quot;index&quot;, onlyPath=false, protocol=&quot;https&quot;, host=&quot;www.example.com&quot;));
// -&gt; &lt;a href=&quot;https://www.example.com/home/index&quot;&gt;Home&lt;/a&gt;

// 10. Link to an anchor on the target page
writeOutput(linkTo(text=&quot;Jump to Comments&quot;, controller=&quot;blog&quot;, action=&quot;post&quot;, key=99, anchor=&quot;comments&quot;));
// -&gt; &lt;a href=&quot;/blog/post/99#comments&quot;&gt;Jump to Comments&lt;/a&gt;
</code></pre>
