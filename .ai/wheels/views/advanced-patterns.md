# Advanced View Patterns

## AJAX and Partial Updates

### Rendering Partials for AJAX

```cfm
<!--- In controller action --->
function updateUser() {
    user = model("user").findByKey(params.id);
    user.update(params.user);
    renderPartial(user); // Returns just the partial HTML
}

<!--- _user.cfm partial for AJAX updates --->
<cfparam name="arguments.user">
<cfoutput>
<div id="user-#arguments.user.id#" class="user-card">
    <h3>#EncodeForHtml(arguments.user.name)#</h3>
    <p>#EncodeForHtml(arguments.user.email)#</p>
    <p>Last updated: #TimeFormat(Now())#</p>
</div>
</cfoutput>
```

### JSON API Views

```cfm
<!-- /app/views/users/show.json.cfm -->
<cfparam name="user">
<cfoutput>
{
    "user": {
        "id": #user.id#,
        "firstname": "#JSStringFormat(user.firstname ?: "")#",
        "lastname": "#JSStringFormat(user.lastname ?: "")#",
        "email": "#JSStringFormat(user.email ?: "")#",
        "role": <cfif IsObject(user.role)>"#JSStringFormat(user.role.name)#"<cfelse>null</cfif>,
        "createdat": "#dateFormat(user.createdat, 'yyyy-mm-dd')#T#timeFormat(user.createdat, 'HH:mm:ss')#Z",
        "updatedat": "#dateFormat(user.updatedat, 'yyyy-mm-dd')#T#timeFormat(user.updatedat, 'HH:mm:ss')#Z"
    }
}
</cfoutput>
```

## Performance and Caching

### Caching Partials

```cfm
<!--- Cache expensive partials --->
<cfoutput>
    #includePartial(partial="expensiveReport", cache=60)# <!--- Cache for 60 minutes --->
</cfoutput>
```

### Asset Optimization

```cfm
<!--- Bundle CSS and JavaScript --->
<cfoutput>
    #styleSheetLinkTag("reset.css,typography.css,application.css")#
    #javaScriptIncludeTag("jquery.js,application.js")#
</cfoutput>
```

### Query Optimization in Views

```cfm
<!--- Store query results to avoid multiple executions --->
<cfset comments = post.comments()>
<cfif comments.recordCount gt 0>
    <h3>Comments (#comments.recordCount#)</h3>
    <cfloop query="comments">
        <div class="comment">
            #comments.content#
        </div>
    </cfloop>
</cfif>
```

## Content Sections and Nested Layouts

### Content Sections

```cfm
<!--- Define content sections in views --->
<cfscript>
    contentFor(head="<link rel='stylesheet' href='user-styles.css'>");
    contentFor(pageTitle="User Profile - " & user.name);
    contentFor(breadcrumb="<a href='/'>Home</a> > <a href='/users'>Users</a> > " & user.name);
</cfscript>

<!--- Use in layout --->
<html>
    <head>
        <title><cfoutput>#includeContent("pageTitle")#</cfoutput></title>
        <cfoutput>#includeContent("head")#</cfoutput>
    </head>
    <body>
        <nav class="breadcrumb">
            <cfoutput>#includeContent("breadcrumb")#</cfoutput>
        </nav>
        <main>
            <cfoutput>#includeContent()#</cfoutput>
        </main>
    </body>
</html>
```

### Layout Inheritance

```cfm
<!--- Base layout: /app/views/layouts/application.cfm --->
<cfoutput>
<!DOCTYPE html>
<html>
    <head>
        <title>#includeContent("title", "MyApp")#</title>
        #includeContent("stylesheets")#
    </head>
    <body class="#includeContent("bodyClass", "")#">
        <header>
            #includePartial("/shared/header")#
        </header>
        <main>
            #includeContent()#
        </main>
        <footer>
            #includePartial("/shared/footer")#
        </footer>
        #includeContent("javascripts")#
    </body>
</html>
</cfoutput>

<!--- Child layout: /app/views/admin/layout.cfm --->
<cfscript>
    contentFor("title", "Admin Panel");
    contentFor("bodyClass", "admin-layout");
    contentFor("stylesheets", styleSheetLinkTag("admin.css"));
</cfscript>

<div class="admin-container">
    <nav class="admin-sidebar">
        <cfoutput>#includePartial("admin/navigation")#</cfoutput>
    </nav>
    <div class="admin-content">
        <cfoutput>#includeContent()#</cfoutput>
    </div>
</div>

<cfscript>
    contentFor("javascripts", javaScriptIncludeTag("admin.js"));
</cfscript>

<cfoutput>#includeLayout("application")#</cfoutput>
```

## Dynamic Content Generation

### Conditional Rendering

```cfm
<cfoutput>
<div class="user-actions">
    <cfif user.canEdit(session.currentUser)>
        #linkTo(text="Edit", route="editUser", key=user.id, class="btn btn-primary")#
    </cfif>

    <cfif user.canDelete(session.currentUser)>
        #buttonTo(text="Delete", route="user", method="delete", key=user.id,
                 class="btn btn-danger", confirm="Are you sure?")#
    </cfif>

    <cfswitch expression="#user.status#">
        <cfcase value="pending">
            #buttonTo(text="Approve", route="approveUser", key=user.id, class="btn btn-success")#
        </cfcase>
        <cfcase value="active">
            #buttonTo(text="Suspend", route="suspendUser", key=user.id, class="btn btn-warning")#
        </cfcase>
        <cfcase value="suspended">
            #buttonTo(text="Reactivate", route="reactivateUser", key=user.id, class="btn btn-info")#
        </cfcase>
    </cfswitch>
</div>
</cfoutput>
```

### Complex Data Display

```cfm
<cfoutput>
<div class="dashboard">
    <div class="stats-grid">
        <cfloop array="#dashboardStats#" index="stat">
            <div class="stat-card stat-#stat.type#">
                <h3>#stat.value#</h3>
                <p>#stat.label#</p>
                <cfif stat.trend neq "neutral">
                    <span class="trend trend-#stat.trend#">
                        #stat.percentage#%
                    </span>
                </cfif>
            </div>
        </cfloop>
    </div>

    <div class="charts">
        <cfif structKeyExists(variables, "chartData") and arrayLen(chartData)>
            <div class="chart-container">
                #includePartial("charts/lineChart", data=chartData)#
            </div>
        </cfif>
    </div>

    <div class="recent-activity">
        <h3>Recent Activity</h3>
        <cfif recentActivities.recordCount>
            <cfloop query="recentActivities">
                #includePartial("activities/item", activity=recentActivities)#
            </cfloop>
        <cfelse>
            <p class="no-activity">No recent activity</p>
        </cfif>
    </div>
</div>
</cfoutput>
```

## Multi-Language Support

### Internationalization Helpers

```cfm
<cfscript>
function t(required string key, struct replacements = {}) {
    // Simple translation function
    local.translation = application.translations[session.locale][arguments.key];

    if (!isDefined("local.translation")) {
        return arguments.key;
    }

    // Replace placeholders
    for (local.placeholder in arguments.replacements) {
        local.translation = replace(local.translation, "{{#local.placeholder#}}", arguments.replacements[local.placeholder], "ALL");
    }

    return local.translation;
}
</cfscript>

<!--- Usage in views --->
<cfoutput>
    <h1>#t("user.profile.title")#</h1>
    <p>#t("user.profile.welcome", {name = user.name})#</p>
</cfoutput>
```

## Error Handling and Debugging

### Development Debug Information

```cfm
<cfif application.environment eq "development">
    <cfoutput>
    <div class="debug-panel">
        <h4>Debug Information</h4>
        <ul>
            <li>Controller: #params.controller#</li>
            <li>Action: #params.action#</li>
            <li>Execution Time: #getTickCount() - request.startTime#ms</li>
            <li>Memory Usage: #NumberFormat(getMemoryUsage().used / 1024 / 1024, "0.00")# MB</li>
        </ul>

        <cfif structKeyExists(variables, "debugQueries") and arrayLen(debugQueries)>
            <h5>Database Queries (#arrayLen(debugQueries)#)</h5>
            <cfloop array="#debugQueries#" index="query">
                <div class="debug-query">
                    <strong>Time:</strong> #query.executionTime#ms<br>
                    <strong>SQL:</strong> <code>#query.sql#</code>
                </div>
            </cfloop>
        </cfif>
    </div>
    </cfoutput>
</cfif>
```

### Custom Error Pages

```cfm
<!--- /app/views/errors/404.cfm --->
<cfscript>
    contentFor("title", "Page Not Found");
</cfscript>

<cfoutput>
<div class="error-page">
    <h1>404 - Page Not Found</h1>
    <p>The page you're looking for doesn't exist.</p>

    <div class="suggestions">
        <h3>Try these instead:</h3>
        <ul>
            <li>#linkTo(text="Home", route="root")#</li>
            <li>#linkTo(text="Browse Users", route="users")#</li>
            <li>#linkTo(text="Contact Support", route="contact")#</li>
        </ul>
    </div>

    <cfif application.environment eq "development">
        <div class="debug-info">
            <h4>Debug Information</h4>
            <p>Requested URL: #cgi.request_url#</p>
            <p>Controller: #params.controller#</p>
            <p>Action: #params.action#</p>
        </div>
    </cfif>
</div>
</cfoutput>
```