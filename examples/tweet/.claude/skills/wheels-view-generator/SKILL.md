---
name: Wheels View Generator
description: Generate Wheels view templates with proper query handling, form helpers, and association display. Use when creating or modifying views, forms, layouts, or partials. Prevents common view errors like query/array confusion and incorrect form helper usage. Handles index views, show views, form views, and layouts with proper CFML syntax.
---

# Wheels View Generator

## When to Use This Skill

- Creating index, show, and form views, layouts, or partials
- Changing forms or how records and associations are displayed

## Conventions

- Views live in `app/views/<controller>/<action>.cfm`. Partials start with an underscore (`_comment.cfm`) and are rendered with `includePartial("comment")`.
- `cfparam` every variable the controller passes, at the top of the view: `<cfparam name="posts" default="">`.
- Wrap output in `<cfoutput>`. Escape user content with `EncodeForHTML()`; the form and link helpers encode for you.
- **Finders return queries, not arrays.** Loop with `<cfloop query="posts">` and read columns as `posts.title`; count with `posts.recordCount`.
- **Don't call association methods inside a query loop.** A query row is not a model object, so `posts.user()` fails. Load the association in the controller with `include="user"` and read the joined columns (`posts.username`), or fetch an object with `model("Post").findByKey(posts.id)` when you need its methods.
- **Use the typed form helpers:** `emailField`, `passwordField`, `numberField`, `urlField`, `telField`, `dateField`, `colorField`, `rangeField`, `searchField` (plus `*Tag` forms) rather than `textField(type="...")`.
- Use `startFormTag()` for forms. It adds the CSRF authenticity token on non-GET forms when the controller calls `protectsFromForgery()` (the base `Controller.cfc` in this app does).
- Wheels helpers take all named arguments once any option is passed: `linkTo(text="Edit", route="editPost", key=post.key())`.

`app/views/layout.cfm` and `app/views/tweets/index.cfm` are working examples in this app.

## Index

```cfm
<cfparam name="posts" default="">
<cfoutput>
<h1>Posts</h1>
#linkTo(text="New post", route="newPost")#

<cfif posts.recordCount>
	<cfloop query="posts">
		<article>
			<h2>#linkTo(text=posts.title, route="post", key=posts.id)#</h2>
			<p>by #EncodeForHTML(posts.username)# on #DateFormat(posts.createdAt, "mmm d, yyyy")#</p>
		</article>
	</cfloop>
	#paginationLinks()#
<cfelse>
	<p>No posts yet.</p>
</cfif>
</cfoutput>
```

The controller supplies `posts = model("Post").findAll(include="user", order="createdAt DESC", page=params.page ?: 1, perPage=20)`, which is why `posts.username` and `paginationLinks()` work.

## Form (shared by new and edit)

```cfm
<!--- app/views/posts/_form.cfm --->
<cfoutput>
#errorMessagesFor("post")#

#textField(objectName="post", property="title", label="Title")#
#textArea(objectName="post", property="body", label="Body")#
#emailField(objectName="post", property="contactEmail", label="Contact email")#
#select(objectName="post", property="categoryId", options=categories, valueField="id", textField="name", includeBlank="Choose one", label="Category")#
#checkBox(objectName="post", property="published", label="Published")#
</cfoutput>
```

```cfm
<!--- app/views/posts/new.cfm --->
<cfparam name="post" default="">
<cfparam name="categories" default="">
<cfoutput>
<h1>New post</h1>
#startFormTag(route="posts", method="post")#
	#includePartial("form")#
	#submitTag(value="Create post")#
#endFormTag()#
</cfoutput>
```

For edit, open the form with `startFormTag(route="post", key=post.key(), method="patch")`. The field helpers read `params.post` naming automatically, so the controller receives `params.post.title` and so on.

## Layout

`app/views/layout.cfm` wraps every view. Inside it, `#includeContent()#` outputs the view, and `#includeContent("title")#` outputs anything a view set with `contentFor("title", "...")`. Show flash messages from the layout with `#flashMessages()#`.

## Before You Finish

- Every controller variable is `cfparam`'d.
- No association method is called on a query row.
- Hand-test the page in a browser: it renders, forms submit and show validation errors, and links go where expected. Passing tests don't show that a view works.

## Related Skills

- **wheels-anti-pattern-detector**: Validates view code
- **wheels-controller-generator**: Creates controllers that supply view data
- **wheels-model-generator**: Creates models displayed in views

Framework reference: https://guides.wheels.dev
