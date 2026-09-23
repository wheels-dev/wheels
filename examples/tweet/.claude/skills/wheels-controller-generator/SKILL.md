---
name: Wheels Controller Generator
description: Generate Wheels MVC controllers with CRUD actions, filters, parameter verification, and proper rendering. Use when creating or modifying controllers, adding actions, implementing filters for authentication/authorization, handling form submissions, or rendering views/JSON. Ensures proper Wheels conventions and prevents common controller errors.
---

# Wheels Controller Generator

## When to Use This Skill

- Creating a controller or adding actions to one
- Adding filters (authentication, authorization, loading a record)
- Handling form submissions, redirects, and flash messages
- Returning JSON from an action

## Conventions

- Controllers are plural PascalCase (`Users.cfc`) and extend `"Controller"` (`app/controllers/Controller.cfc`).
- Filters, `verifies()`, and `provides()` go in `config()`. If the controller defines `config()`, call `super.config()` first: the base controller's `config()` is where `protectsFromForgery()` runs, and overriding it without `super` switches CSRF protection off for that controller.
- Filter functions are `private`. A public function is a routable action, so a public `authenticate()` could be requested as a URL.
- Wheels functions take either all positional or all named arguments. Once you pass an option, name every argument: `filters(through="requireAuth", except="index,show")`.
- Variables set in an action are available in its view without passing them. Every view should `cfparam` the variables it uses.
- Model finders return query objects (`findAll`) or model objects (`findByKey`, `findOne`, `new`, `create`); `findByKey` returns `false` when nothing matches.

The actions in `app/controllers/Tweets.cfc` and `Users.cfc` are working examples in this app.

## CRUD Template

```cfm
component extends="Controller" {

	function config() {
		super.config();
		filters(through="requireAuth", except="index,show");
		filters(through="findPost", only="show,edit,update,delete");
		verifies(only="show,edit,update,delete", params="key", paramsTypes="integer");
	}

	function index() {
		posts = model("Post").findAll(order="createdAt DESC", page=params.page ?: 1, perPage=20);
	}

	function show() {
	}

	function new() {
		post = model("Post").new();
	}

	function create() {
		post = model("Post").new(params.post);
		if (post.save()) {
			flashInsert(success="Post created.");
			redirectTo(action="show", key=post.key());
		} else {
			renderView(action="new");
		}
	}

	function edit() {
	}

	function update() {
		if (post.update(params.post)) {
			flashInsert(success="Post updated.");
			redirectTo(action="show", key=post.key());
		} else {
			renderView(action="edit");
		}
	}

	function delete() {
		post.delete();
		flashInsert(success="Post deleted.");
		redirectTo(action="index");
	}

	private function findPost() {
		post = model("Post").findByKey(params.key);
		if (!IsObject(post)) {
			flashInsert(error="Post not found.");
			redirectTo(action="index");
		}
	}

	private function requireAuth() {
		if (!StructKeyExists(session, "userId")) {
			redirectTo(controller="sessions", action="new");
		}
	}

}
```

On a failed save, render the form again with `renderView()` rather than redirecting, so the object keeps its values and its validation errors for `errorMessagesFor()`.

## JSON

```cfm
function config() {
	super.config();
	provides("html,json");
}

function index() {
	posts = model("Post").findAll(order="createdAt DESC");
	renderWith(data=posts);
}
```

`renderWith()` renders the view for HTML requests and serializes `data` for JSON ones (by `format=json` in the URL or the `Accept` header). For a JSON-only endpoint, `renderText(SerializeJSON(...))` also works, and `renderNothing(status=204)` returns an empty response.

## Other Helpers

| Need | Call |
|---|---|
| Redirect to the previous page | `redirectTo(back=true)` |
| Redirect to a named route | `redirectTo(route="post", key=post.key())` |
| Keep flash for one more request | `flashKeep()` |
| Render a partial | `renderPartial(partial="comment")` |
| Send a file | `sendFile(file="report.pdf")` |

## Before You Finish

- `super.config()` is called if `config()` is defined.
- Filters are `private`, and every multi-argument call uses named arguments.
- Each action has a view, or renders or redirects explicitly.
- Hand-test the flow in a browser: forms submit, validation errors show, redirects land where expected.

## Related Skills

- **wheels-anti-pattern-detector**: Validates controller code
- **wheels-view-generator**: Creates views for controller actions
- **wheels-test-generator**: Creates controller specs
- **wheels-model-generator**: Creates models used by controller

Framework reference: https://guides.wheels.dev
