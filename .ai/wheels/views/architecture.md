# View Architecture and Structure

## Overview

Views in Wheels are template files that generate the HTML (or other content) that users see in their browsers. They follow the MVC (Model-View-Controller) pattern where the controller sets up data and the view handles presentation. Views are written in CFML and can include HTML, CSS, JavaScript, and any other content type.

## File Structure and Conventions

### View File Location

- All view files are stored in `/app/views/`
- Each controller gets its own subfolder: `/app/views/[controller-name]/`
- View files use `.cfm` extension (not `.cfc`)
- Standard action views are named after the action: `/app/views/users/show.cfm`

### Naming Conventions

- **Actions**: Named after controller actions (`index.cfm`, `show.cfm`, `new.cfm`, `edit.cfm`)
- **Partials**: Start with underscore (`_form.cfm`, `_user.cfm`, `_navigation.cfm`)
- **Layouts**: Named `layout.cfm` (controller-specific) or placed in `/app/views/layout.cfm` (global)
- **Shared views**: Place in `/app/views/shared/` for cross-controller use

### File Structure Example

```
/app/views/
├── layout.cfm                 (global layout)
├── helpers.cfm               (global view helpers)
├── users/
│   ├── layout.cfm            (users controller layout)
│   ├── index.cfm             (users#index action)
│   ├── show.cfm              (users#show action)
│   ├── new.cfm               (users#new action)
│   ├── edit.cfm              (users#edit action)
│   └── _form.cfm             (partial for user form)
├── shared/
│   ├── _navigation.cfm       (shared navigation partial)
│   └── _footer.cfm           (shared footer partial)
└── emails/
    └── usermailer/
        └── welcome.cfm       (email template)
```

## Basic View Structure

### Simple View Example

```cfm
<!--- /app/views/users/show.cfm --->
<cfparam name="user">
<cfoutput>
<h1>User Profile</h1>
<div class="user-details">
    <h2>#EncodeForHtml(user.name)#</h2>
    <p>Email: #EncodeForHtml(user.email)#</p>
    <p>Created: #DateFormat(user.createdAt, "mmmm dd, yyyy")#</p>
</div>

<div class="actions">
    #linkTo(text="Edit User", route="editUser", key=user.id)#
    #linkTo(text="All Users", route="users")#
</div>
</cfoutput>
```

### Basic HTML Structure

```cfm
<!--- Always wrap output in cfoutput tags --->
<cfoutput>
    <!-- Your HTML content here -->
    <h1>#pageTitle#</h1>
    <p>#user.description#</p>
</cfoutput>
```

## Content Types and Format-Specific Views

### Multiple Format Support

```cfm
<!--- Controller provides formats --->
function config() {
    provides("html,json,xml");
}

<!--- Default view: show.cfm --->
<cfoutput>
<h1>User: #user.name#</h1>
<p>Email: #user.email#</p>
</cfoutput>

<!--- JSON view: show.json.cfm --->
<cfoutput>
#renderWith(user)#
</cfoutput>

<!--- XML view: show.xml.cfm --->
<cfoutput>
#renderWith(user, xml=true)#
</cfoutput>
```

## Best Practices

### 1. Always Use cfoutput

```cfm
<!--- Correct --->
<cfoutput>
    <h1>#user.name#</h1>
</cfoutput>

<!--- Incorrect --->
<h1><cfoutput>#user.name#</cfoutput></h1>
```

### 2. Encode User Data

```cfm
<!--- Always encode user-generated content --->
<cfoutput>
    <h1>#EncodeForHtml(user.name)#</h1>
    <p>#EncodeForHtml(user.bio)#</p>
</cfoutput>
```

### 3. Use Partials for Reusability

```cfm
<!--- Extract repeated code into partials --->
<cfoutput>
    <cfloop query="users">
        #includePartial(partial="userCard", user=users)#
    </cfloop>
</cfoutput>
```

### 4. Organize Views Logically

- Group related partials in controller folders
- Use `/shared/` for cross-controller partials
- Name partials descriptively (`_userCard.cfm`, not `_card.cfm`)

### 5. Use Wheels Helpers

```cfm
<!--- Prefer Wheels helpers over raw HTML --->
<cfoutput>
    <!--- Good --->
    #linkTo(text="Edit", route="editUser", key=user.id)#

    <!--- Avoid when possible --->
    <a href="/users/#user.id#/edit">Edit</a>
</cfoutput>
```