# Content For

## Description
Allow views to populate specific sections of layouts, enabling flexible page structure and dynamic content insertion.

## Key Points
- Use `contentFor("sectionName", "content")` in views
- Reference sections in layouts with `contentFor("sectionName")`
- Support for both simple text and complex HTML
- Can set default values in layout
- Useful for page titles, scripts, stylesheets

## Code Sample
```cfm
<!-- In view: /app/views/users/show.cfm -->
<cfoutput>
#contentFor("title", "User Profile - #user.fullName()#")#

#contentFor("stylesheets", styleSheetLinkTag("profiles"))#

#contentFor("javascript", javaScriptIncludeTag("user-profile"))#

#contentFor("breadcrumbs", '
<nav aria-label="breadcrumb">
    <ol class="breadcrumb">
        <li class="breadcrumb-item">' & linkTo(controller="home", action="index", text="Home") & '</li>
        <li class="breadcrumb-item">' & linkTo(controller="users", action="index", text="Users") & '</li>
        <li class="breadcrumb-item active">#user.fullName()#</li>
    </ol>
</nav>')#

<div class="user-profile">
    <h1>#user.fullName()#</h1>
    <p>Email: #user.email#</p>
</div>
</cfoutput>

<!-- In layout: /app/views/layout.cfm -->
<!DOCTYPE html>
<html>
<head>
    <title>#contentFor("title", "My Application")#</title>
    #styleSheetLinkTag("application")#

    <!-- Page-specific styles -->
    #contentFor("stylesheets")#
</head>
<body>
    <!-- Breadcrumb navigation -->
    #contentFor("breadcrumbs")#

    <main>
        #includeContent()#
    </main>

    #javaScriptIncludeTag("application")#

    <!-- Page-specific JavaScript -->
    #contentFor("javascript")#
</body>
</html>
```

## Usage
1. Call `contentFor("section", "content")` in views
2. Reference sections in layouts with `contentFor("section")`
3. Provide default values: `contentFor("section", "default")`
4. Use for page titles, meta tags, scripts, stylesheets
5. Can include complex HTML and helper function calls

## Related
- [Layout Structure](./structure.md)
- [Partials](./partials.md)
- [Custom Helpers](../helpers/custom.md)

## Important Notes
- Content must be set before layout is rendered
- Can override default values set in layout
- Useful for SEO meta tags and page-specific resources
- Content is not escaped - handle security appropriately
- Multiple calls to same section will concatenate content