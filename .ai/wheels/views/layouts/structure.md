# Layout Structure

## Description
Layouts provide the common HTML structure that wraps individual view templates, reducing duplication and ensuring consistency.

## Key Points
- Default layout is `/app/views/layout.cfm`
- Use `includeContent()` to render view content
- Support multiple layouts for different sections
- `contentFor()` allows views to set layout sections
- Can be disabled for AJAX/API responses

## Code Sample
```cfm
<!-- /app/views/layout.cfm - Default layout -->
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>#contentFor("title", "My Application")#</title>

    #csrfMetaTags()#
    #styleSheetLinkTag("application")#

    <!-- Page-specific stylesheets -->
    #contentFor("stylesheets")#
</head>
<body>
    <header class="navbar">
        #linkTo(controller="home", action="index", text="Home")#
        <nav>
            <!-- Navigation items -->
        </nav>
    </header>

    <main class="container">
        <!-- Flash messages -->
        #flashMessages()#

        <!-- Page content from individual views -->
        #includeContent()#
    </main>

    <footer>
        <p>&copy; #Year(Now())# My Company</p>
    </footer>

    #javaScriptIncludeTag("application")#

    <!-- Page-specific JavaScript -->
    #contentFor("javascript")#
</body>
</html>

<!-- /app/views/admin/layout.cfm - Admin layout -->
<!DOCTYPE html>
<html>
<head>
    <title>Admin - #contentFor("title", "Dashboard")#</title>
    #styleSheetLinkTag("admin")#
</head>
<body class="admin-layout">
    <aside class="sidebar">
        <!-- Admin navigation -->
    </aside>

    <main class="admin-content">
        #includeContent()#
    </main>
</body>
</html>
```

## Usage
1. Create layout files in `/app/views/`
2. Use `includeContent()` where view content should appear
3. Use `contentFor()` in views to populate layout sections
4. Specify custom layouts in controller with `renderView(layout="admin")`
5. Disable layouts with `layout=false` for partial content

## Related
- [Content For](./content-for.md)
- [Partials](./partials.md)
- [Rendering Views](../../controllers/rendering/views.md)

## Important Notes
- Default layout automatically applied to all views
- Custom layouts stored in subfolders or with descriptive names
- CSRF protection should be included in layout head
- Flash messages typically displayed in layout
- Disable layouts for AJAX responses and API endpoints