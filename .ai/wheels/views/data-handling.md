# Data Handling in Views

## 🚨 CRITICAL: Wheels Data Types

**Wheels associations and model methods return QUERIES, not ARRAYS. This is the #2 most common view error.**

### ❌ WRONG - Treating Queries as Arrays

```cfm
<!--- Model associations return queries, NOT arrays --->
<cfset commentCount = ArrayLen(post.comments())>  <!-- ERROR! -->
<cfset userCount = ArrayLen(model("User").findAll())>  <!-- ERROR! -->

<!--- Can't loop queries as arrays --->
<cfloop array="#post.comments()#" index="comment">  <!-- ERROR! -->
    #comment.content#
</cfloop>
```

### ✅ CORRECT - Using Query Methods and Loops

```cfm
<!--- Use .recordCount for query record counts --->
<cfset commentCount = post.comments().recordCount>
<cfset userCount = model("User").findAll().recordCount>

<!--- Loop queries with query="..." --->
<cfset comments = post.comments()>
<cfloop query="comments">
    #comments.content#  <!--- Access fields directly from query --->
</cfloop>

<!--- Check if query has records --->
<cfif post.comments().recordCount gt 0>
    <cfloop query="post.comments()">
        <p>#post.comments().content#</p>
    </cfloop>
<cfelse>
    <p>No comments found.</p>
</cfif>
```

### 📊 Query vs Array Reference

| **Data Type** | **Count Method** | **Loop Method** | **Check if Empty** |
|---------------|------------------|-----------------|-------------------|
| **Query** | `.recordCount` | `<cfloop query="...">` | `query.recordCount gt 0` |
| **Array** | `ArrayLen()` | `<cfloop array="...">` | `ArrayLen(array) gt 0` |

### Common View Patterns - CORRECT Examples

```cfm
<!--- Association counts --->
<cfset postCount = user.posts().recordCount>
<cfset commentCount = post.comments().recordCount>

<!--- Association loops --->
<cfloop query="user.posts()">
    <h3>#user.posts().title#</h3>
</cfloop>

<!--- Model finder results --->
<cfset users = model("User").findAll()>
<cfif users.recordCount gt 0>
    <cfloop query="users">
        <p>#users.name# - #users.email#</p>
    </cfloop>
</cfif>

<!--- Conditional display based on associations --->
<cfif post.comments().recordCount gt 0>
    <h3>Comments (#post.comments().recordCount#)</h3>
    <cfloop query="post.comments()">
        <div class="comment">
            <strong>#post.comments().author#:</strong>
            #post.comments().content#
        </div>
    </cfloop>
<cfelse>
    <p>No comments yet.</p>
</cfif>
```

**⚡ MEMORY RULE**: In Wheels views, if it comes from a model (associations, finders), it's a QUERY. Use `.recordCount` and `<cfloop query="...">`.

## Variable Scoping

```cfm
<!--- Variables set in controller are available unscoped --->
<cfoutput>
    <h1>#pageTitle#</h1>  <!--- Set as variables.pageTitle in controller --->
    <p>User: #user.name#</p>  <!--- Set as variables.user in controller --->
</cfoutput>

<!--- Access params struct (though controller should handle this) --->
<cfoutput>
    <p>Current page: #params.page#</p>
</cfoutput>
```

## Data Validation and Security

```cfm
<!--- Always encode user data for HTML output --->
<cfoutput>
    <h1>#EncodeForHtml(user.name)#</h1>
    <p>Bio: #EncodeForHtml(user.bio)#</p>

    <!--- For URLs --->
    <a href="mailto:#EncodeForUrl(user.email)#">Contact</a>

    <!--- For HTML attributes --->
    <div title="#EncodeForHtmlAttribute(user.bio)#">User Info</div>
</cfoutput>

<!--- Wheels helpers handle encoding automatically --->
<cfoutput>
    #linkTo(text=user.name, route="user", key=user.id)# <!--- Automatically encoded --->
    #textField(objectName="user", property="name")# <!--- Automatically encoded --->
</cfoutput>
```

## Parameter Validation

```cfm
<!--- Always validate expected variables --->
<cfparam name="user">
<cfparam name="showActions" default="true">
```