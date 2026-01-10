---
description: >-
  Wheels includes a plethora of view helpers to help you transform data into a
  format more easily consumed by your applications' users
---

# Date, Media, and Text Helpers

Wheels's included view helper functions can help you out in those tricky little tasks that need to be performed in the front-end of your web applications. Although they are called miscellaneous, they are in fact categorized into 3 categories:

* Date Helpers
* Media Helpers
* Text Helpers

We also have separate chapters about Wheels form helpers in [Form Helpers and Showing Errors](https://wheels.dev/3.0.0/guides/displaying-views-to-users/form-helpers-and-showing-errors) and creating your own helpers in [Creating Custom View Helpers](https://wheels.dev/3.0.0/guides/displaying-views-to-users/creating-custom-view-helpers).

### Date Helpers

Wheels does a good job at simplifying the not so fun task of date and time transformations.

Let's say that you have a comment section in your application, which shows the title, comment, and date/time of its publication. In the old days, your code would have looked something like this:

```javascript
<cfoutput query="comments">
    <div class="comment">
        <h2>#comments.title#</h2>

        <p class="timestamp">
            #DateFormat(comments.createdAt, "mmmm d, yyyy")#
            #LCase(TimeFormat(comments.createdAt, "h:mm tt"))#</p>
        <p>#comments.comment#</p>
    </div>
</cfoutput>
```

That works, but it's pretty tedious. And if you think about it, the date will be formatted in a way that is not that meaningful to the end user.

Instead of "April 27, 2009 10:10 pm," it may be more helpful to display "a few minutes ago" or "2 hours ago." This can be accomplished with a Wheels date helper called [timeAgoInWords()](https://wheels.dev/api/v3.0.0/controller.timeagoinwords.html).

```javascript
<cfoutput query="comments">
    <div class="comment">
        <h2>#comments.title#</h2>

        <p class="timestamp">(#timeAgoInWords(comments.createdAt)#)</p>
        <p>#comments.comment#</p>
    </div>
</cfoutput>
```

With that minimal change, you have a prettier presentation for your end users. And most important of all, it didn't require you to do anything fancy in your code.

### Media Helpers

Working with media is also a walk in the park with Wheels. Let's jump into a few quick examples.

**Style Sheets**

First, to include CSS files in your layout, you can use the [styleSheetLinkTag()](https://wheels.dev/api/v3.0.0/controller.styleSheetLinkTag.html) function:

```javascript
<!--- layout.cfm --->
<cfoutput>
    #styleSheetLinkTag("main")#
</cfoutput>
```

This will generate the `<link>` tag for you with everything needed to include the file at `public/stylesheets/main.css`.

If you need to include more than one style sheet and change the media type to "print" for another, there are arguments for that as well:&#x20;

```javascript
#styleSheetLinkTag(sources="main,blog")#
#styleSheetLinkTag(source="printer", media="print")#
```

Lastly, you can also link to stylesheets at a different domain or subdomain by specifying the full URL:

```javascript
#styleSheetLinkTag(    source="http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.0/themes/cupertino/jquery-ui.css"
)#
```

**JavaScript Files**

Including JavaScript files is just as simple with the [javaScriptIncludeTag()](https://wheels.dev/api/v3.0.0/controller.javascriptincludetag.html) helper. This time, files are referenced from the _**public/javascripts**_ folder.

```javascript
#javaScriptIncludeTag("jquery")#
```

Like with style sheets, you can also specify lists of JavaScript includes as well as full URLs:

```javascript
#javaScriptIncludeTag("https://ajax.googleapis.com/ajax/libs/jquery/1.4.4/jquery.min.js")#
```

**Displaying Images**

Wheels's [imageTag()](https://wheels.dev/api/v3.0.0/controller.imagetag.html) helper also provides some simple, yet powerful functionality:

```javascript
<cfoutput>
    #imageTag("logo.png")#
</cfoutput>
```

With this simple call, Wheels will generate the `<img>` tag for `public/images/logo.png` and also set the `width`, `height` and `alt` attributes automatically for you (based on image dimensions and the image file name). Wheels will also cache this information for later use in your application.

If you need to override the `alt` attribute for better accessibility, you can still do that too:

```javascript
#imageTag(source="logo.png", alt="ColdFusion on Wheels")#
```

#### Text Helpers

To illustrate what the text helpers can help you with, let's see a piece of code that includes 2 of the text helpers in a simple search results page.

```javascript
<!--- Query of search results --->
<cfparam name="searchResults" type="query">

<!--- Search query provided by user --->
<cfparam name="params.q" type="string">

<cfoutput>
    <p>
       #highlight(text="Your search for #params.q#", phrases=params.q)#
       returned #searchResults.RecordCount#
       #pluralize(word="result", count=searchResults.RecordCount)#.
    </p>
</cfoutput>
```

That code will highlight all occurrences of `params.q` and will pluralize the word "result" to "results" if the number of records in `searchResults` is greater than 1. How about them apples? No `<cfif>` statements, no extra lines, no nothing.

The functions we have shown in this chapter are only the tip of the iceberg when it comes to helper functions. There's plenty more, so don't forget to check out the View Helper Functions API.
