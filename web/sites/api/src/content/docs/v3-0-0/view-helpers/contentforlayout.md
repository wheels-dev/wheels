---
title: contentForLayout()
description: "contentForLayout() is used to render the main content of the current view inside a layout. In Wheels, when a controller action renders a view, that view generat"
sidebar:
  label: contentForLayout()
  order: 0
---

## Signature

`contentForLayout()` — returns `string`

**Available in:** `controller`
**Category:** Miscellaneous Functions

## Description

contentForLayout() is used to render the main content of the current view inside a layout. In Wheels, when a controller action renders a view, that view generates content. This content can then be injected into the layout at the appropriate place using contentForLayout(). Essentially, it’s the placeholder for the view’s body content in your layout template.




## Examples

<pre><code class='javascript'>Controller:
// PostsController.cfc
function show() {
    var post = model("post").findByKey(params.id);
}

View (views/posts/show.cfm):
&lt;h2&gt;#post.title#&lt;/h2&gt;
&lt;p&gt;#post.body#&lt;/p&gt;

Layout (views/layout.cfm):
&lt;html&gt;
&lt;head&gt;
    &lt;title&gt;Blog&lt;/title&gt;
&lt;/head&gt;
&lt;body&gt;
    &lt;nav&gt;Home | Posts&lt;/nav&gt;

    &lt;!-- Inject view content --&gt;
    #contentForLayout()#

    &lt;footer&gt;&copy; 2025 My Blog&lt;/footer&gt;
&lt;/body&gt;
&lt;/html&gt;

Output when visiting /posts/show?id=1:
&lt;html&gt;
&lt;head&gt;
    &lt;title&gt;Blog&lt;/title&gt;
&lt;/head&gt;
&lt;body&gt;
    &lt;nav&gt;Home | Posts&lt;/nav&gt;

    &lt;h2&gt;Hello World&lt;/h2&gt;
    &lt;p&gt;This is my first post!&lt;/p&gt;

    &lt;footer&gt;&copy; 2025 My Blog&lt;/footer&gt;
&lt;/body&gt;
&lt;/html&gt;</code></pre>
