---
title: CFWheels HTMX Plugin published
slug: cfwheels-htmx-plugin-published
publishedAt: '2022-06-21T04:55:03.000Z'
updatedAt: '2025-06-02T13:08:53.000Z'
author: Peter Amiri
tags: []
categories: []
excerpt: >-
  A few weeks ago I published a Todo
  app(/blog/todomvc-implementation-with-cfwheels-and-htmx/) using CFWheels on
  the backend and HTMX to provide the interactivity on the front end to make the
  app loo...
coverImage: null
legacyId: '123'
---
A few weeks ago I published a [Todo app](/blog/todomvc-implementation-with-cfwheels-and-htmx/) using CFWheels on the backend and HTMX to provide the interactivity on the front end to make the app look and feel like a full blown SPA app. As I was developing that app I ran into a few things that I wish we had to make development with HTMX a little easier. But I'm getting ahead of myself.

### What is HTMX

Well, HTMX was released a couple of years ago and in that short time has just about exploded in the django community. So what is HTMX, HTMX tries to answer the following questions:

1.  Why should only `[<a>](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/a)` and `[<form>](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/form)` be able to make HTTP requests?
2.  Why should only `[click](https://developer.mozilla.org/en-US/docs/Web/API/Element/click_event)` & `[submit](https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/submit_event)` events trigger them?
3.  Why should only `[GET](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/GET)` & `[POST](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST)` methods be [available](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods)?
4.  Why should you only be able to replace the **entire** screen?

By removing these arbitrary constraints, htmx completes HTML as a [hypertext](https://en.wikipedia.org/wiki/Hypertext) medium. You may even start wondering why these features weren't in HTML in the first place. So let's look at an examples.

PlainBashC++C#CSSDiffHTML/XMLJavaJavaScriptMarkdownPHPPythonRubySQL

<script src="https://unpkg.com/htmx.org@1.7.0"></script>

<!-- have a button POST a click via AJAX -->

<button hx-post="/clicked" hx-swap="outerHTML">

Click Me

</button>

This block of code tells the browser:

> When a user clicks on this button, issue an AJAX request to /clicked, and replace the entire button with the HTML response.

Let's look at a typical anchor tag:

PlainBashC++C#CSSDiffHTML/XMLJavaJavaScriptMarkdownPHPPythonRubySQL

<a href="/blog">Blog</a>

This anchor tag tells the browser:

> When a user clicks on this link, issue an HTTP GET request to '/blog' and load the response content into the browser window.

You can see how HTMX feels like a familiar extension to HTML. With this in mind lets look at a following block of HTML:

PlainBashC++C#CSSDiffHTML/XMLJavaJavaScriptMarkdownPHPPythonRubySQL

<button hx-post="/clicked"

hx-trigger="click"

hx-target="#parent-div"

hx-swap="outerHTML"

\>

Click Me!

</button>

This tells HTMX:

> When a user clicks on this button, issue an HTTP POST request to '/clicked' and use the content from the response to replace the element with the id `parent-div` in the DOM

So by using `hx-get`, `hx-post`, `hx-put`, `hx-patch`, or `hx-delete` we gain access to all the HTTP verbs. Imagine a delete button on a table row that actually issues a HTTP Delete to your backend.

The `hx-trigger` attribute gives us access to all the page events. HTML elements have sensible defaults, the `button` tag will get triggered by a click by default and an `input` tag will get triggered by a change event by default. But there are some special events as well, like the `load` event that will trigger the action when the page is initially loaded or the `revealed` event that will trigger the action, when the element scrolls into view. Think of an infinite scroll UX pattern where an element scrolls into view, which triggers a call to the backend to load more data that gets added to the bottom of the page.

The `hx-target` attribute lets you specify a different tag to target than the element that triggered the event. You have the typical CSS selectors but also some special syntax like `closest TR` to target the closest table row.

The last attribute shown in the example above is the `hx-swap` which specifies how to swap the response into the element. By default, the response replaces the `innerHTML` of the target element but you can just as easily replace the entire target element by using `outerHTML`. There are a few more designators that allow you to finely control placing the response before or after the target element in its parent element or at the begging of or end of a target's child elements.

This is just scratching the surface of what HTMX can do but you should be getting the picture. By sprinkling in a handful of HTML attributes into your markup you can gain interactivity that was the domain of full blown JavaScript frontend frameworks in the past.

### Why should we care as CFWheels developers

By default HTMX is backend agnostic. It just deals with HTML and doesn't care what backend technology you use to generate it. This could just as easily be used in a plain vanilla CFML app or your framework of choice, hopefully it would be CFWheels since you are here reading this. Wheels has some built in features that make working with HTMX a breeze. We already have a templating system, we already have a router and controllers to intercept the HTTP request. We have a number of rendering methods that make responding to requests simple.

If the request is a for a full page, use the `renderView()` method or simply let the controller hand the request off to the view which in turn renders the view page. If the request is for a portion of the final page then use the `renderPartial()` method and return a snippet of code tucked away in a partial. The same partial could be used by your initial view page, keeping your code DRY. Sometimes, you just want to return a small bit of text or no text at all and it doesn't make sense to build out a view or partial for every instance of these scenarios, that's when the `renderText()` method comes in handy. Imagine a typical index page from a CRUD application that lists a bunch of rows of data and some action buttons on each row. Let's assume, one of these buttons is a delete button. Look at the following code:

PlainBashC++C#CSSDiffHTML/XMLJavaJavaScriptMarkdownPHPPythonRubySQL

// image this button on a table row

<button hx-delete="/products/15"

hx-target="closest hr"

hx-swap="outerHTML"

hx-confirm="Are you sure?">

Delete

</button>

  

// imagine this code in your action

function delete() {

aProduct = model("product").findByKey(params.key);

aProduct.delete();

renderText("");

}

So what does the above combination do:

> When the user clicks on the Delete button, prompt the user to make sure they are sure they wish to delete the record, if the user affirms the request, issue a DELETE request to the server. The server in turn deletes the record and sends back an empty text response to the client. When the response comes back to the frontend, find the closes table row, and remove it from the table.

We just made an Ajax call to the server, removed the record from the database, and correspondingly updated the UI by just removing a single element from the DOM.

### What does this plugin do?

By default, HTMX adds some request headers to the call sent to the backend which can be interrogated to see if the request is in fact an HTMX request. If the request is actually an HTMX request, some additional request headers are made available which can add more color to the call being processed. This plugin automatically adds these header elements to the `params` structure which makes them automatically available to your controller actions. This makes it easier to work with this data and incorporate it into your request processing logic. Take a look at the following example:

PlainBashC++C#CSSDiffHTML/XMLJavaJavaScriptMarkdownPHPPythonRubySQL

function index() {

if (params.htmx.reqeust) {

renderPartial(partial="myPartial", layout="false");

}

}

This code block says:

> When a request comes in to the index action of the controller, check to see if this is an HTMX request and if it is, respond with the `mypartial` partial and don't wrap it with the layout. Otherwise respond with the `index` view page of the current controller.

Think of a paginated index page, where the first call to the index action sends the view with the first page of data and a button or element on the page triggers additional calls to the same action but this time only the next page of data is sent to the front end.

### Installing the Plugin

To install this plugin, issue the following command from the root of your application in a CommandBox prompt:

PlainBashC++C#CSSDiffHTML/XMLJavaJavaScriptMarkdownPHPPythonRubySQL

install cfwheels-htmx-plugin

Once installed, reload your application and you're off to the races.
