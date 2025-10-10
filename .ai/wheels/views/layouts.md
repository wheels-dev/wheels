# Layouts in CFWheels

## Layout System Overview

Layouts in CFWheels provide a way to wrap your view content with common HTML structure, navigation, headers, and footers. The layout system supports global layouts, controller-specific layouts, and nested layouts.

## Global Layout

The default layout at `/app/views/layout.cfm` wraps all views unless overridden:

```cfm
<!--- /app/views/layout.cfm --->
<cfif application.contentOnly>
    <cfoutput>
        #flashMessages()#
        #includeContent()#
    </cfoutput>
<cfelse>
<cfoutput>
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        #csrfMetaTags()#
        <title>#contentFor("title", "My App")#</title>
    </head>
    <body>
        <nav>
            <a href="#urlFor(controller='home', action='index')#">Home</a>
        </nav>

        #flashMessages()#

        <main>
            #includeContent()#
        </main>

        <footer>
            &copy; #Year(Now())# My App
        </footer>
    </body>
</html>
</cfoutput>
</cfif>
```

**Critical Rules:**
- ✅ **Open `<cfoutput>` immediately after `<cfelse>`** - wraps entire HTML
- ✅ **Close `</cfoutput>` immediately before `</cfif>`** - at end of layout
- ❌ **Do NOT nest `<cfoutput>` blocks** - single block for all HTML
- ✅ **All CFML expressions must be inside the cfoutput block** (`#urlFor()#`, `#Year()#`, etc.)

**Why This Structure:**
- The `application.contentOnly` branch handles API/JSON responses (no HTML wrapper)
- The main HTML branch needs all dynamic content in one `<cfoutput>` block
- Nested cfoutput blocks are redundant and can cause issues

## Controller-Specific Layout

Create `/app/views/[controller]/layout.cfm` to override global layout:

```cfm
<!--- /app/views/admin/layout.cfm --->
<cfoutput>
<html>
    <head>
        <title>Admin Panel</title>
        #csrfMetaTags()#
    </head>
    <body class="admin">
        <nav class="admin-nav">
            #includePartial("/shared/adminNav")#
        </nav>
        <main>
            #flashMessages()#
            #includeContent()#
        </main>
    </body>
</html>
</cfoutput>
```

## Using Different Layouts

Override layout in controller action:

```cfm
// In controller
function display() {
    renderView(layout="visitorLayout");
}
```

## Nested Layouts

Use `includeLayout()` and `contentFor()` for layout inheritance:

```cfm
<!--- Child layout --->
<cfscript>
    contentFor(pageTitle="My Custom Title");
</cfscript>
<cfoutput>#includeLayout("layout")#</cfoutput>

<!--- Parent layout --->
<html>
    <head>
        <title><cfoutput>#includeContent("pageTitle")#</cfoutput></title>
    </head>
    <body>
        <cfoutput>#includeContent()#</cfoutput>
    </body>
</html>
```

## Content Sections

Define content sections in views for use in layouts:

```cfm
<!--- Define content sections in views --->
<cfscript>
    contentFor(head="<link rel='stylesheet' href='user-styles.css'>");
    contentFor(pageTitle="User Profile - " & user.name);
</cfscript>

<!--- Use in layout --->
<html>
    <head>
        <title><cfoutput>#includeContent("pageTitle")#</cfoutput></title>
        <cfoutput>#includeContent("head")#</cfoutput>
    </head>
    <body>
        <cfoutput>#includeContent()#</cfoutput>
    </body>
</html>
```

## Complete Layout Example

```cfm
<!--- /app/views/layout.cfm --->
<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    #csrfMetaTags()#
    <title>#contentFor("title", "MyApp")#</title>

    #styleSheetLinkTag("application")#
    #javaScriptIncludeTag("application")#

    #contentFor("head")#
</head>
<body>
    <nav class="navbar">
        <div class="container">
            #linkTo(route="root", text="MyApp", class="navbar-brand")#
            <ul class="nav">
                <li>#linkTo(route="users", text="Users")#</li>
                <li>#linkTo(route="orders", text="Orders")#</li>
            </ul>
        </div>
    </nav>

    <main class="container">
        #flashMessages()#
        #includeContent()#
    </main>

    <footer>
        #contentFor("footer")#
    </footer>
</body>
</html>
</cfoutput>
```

## Layout Usage in Views

```cfm
<!--- In a view file --->
<cfscript>
    contentFor("title", "User List - MyApp");
    contentFor("head", "<link rel='stylesheet' href='/css/users.css'>");
</cfscript>

<cfoutput>
<h1>Users</h1>
<div class="user-list">
    <!-- User list content -->
</div>
</cfoutput>
```