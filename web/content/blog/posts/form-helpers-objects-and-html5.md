---
title: 'Form Helpers in Wheels 4.0: Object Forms, HTML5 Fields, and Error Rendering'
slug: form-helpers-objects-and-html5
publishedAt: '2026-07-02T14:00:00.000Z'
updatedAt: '2026-06-19T15:10:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - views
  - forms
  - helpers
categories: []
excerpt: >-
  A worked how-to on Wheels 4.0 form helpers: object-bound fields that
  round-trip into params.user.email, the real HTML5 single-input helpers, and
  the two error-rendering helpers — plus the sharp edges that bite first.
coverImage: null
---

You've written this form by hand at least once. A `<form action="/users">` with a dozen `<input name="user[email]">` tags, each one with a hand-typed `value="#user.email#"`, each one with a hand-typed `id` so the `<label for="...">` lines up, and a block at the top that loops over `user.allErrors()` to print the validation messages. It works. Then you add a field, and now you've got eleven correct inputs and one where you fat-fingered the `name` bracket, so that field silently never saves. Then validation fails, the form re-renders, and the value you typed is gone because you forgot to re-populate that one input.

Every one of those bugs is a thing the framework already knows how to do for you. Wheels 4.0's form helpers exist precisely so you stop hand-typing the `name`, the `id`, the `value`, the `<label>`, the `maxlength`, and the error wrapper — and stop getting them subtly wrong. This post is the working tour: object-bound fields that round-trip cleanly into `params.user`, the HTML5 single-input helpers that actually exist (and the ones that don't), and the two error-rendering helpers, with the sharp edges that bite first called out at the end.

## The one mental model: objectName is a string

Here's the thing to internalize before anything else, because it's the part everyone gets wrong on the first try. When you call a field helper, you pass the **variable name** of your object as a string — not the object itself.

```cfm
#textField(objectName="user", property="email")#
```

`objectName="user"` means "go find the variable called `user` in this view's scope and read its `email` property." The helper resolves `variables["user"]` for you. Pass the actual object instance instead of its name and you get a `Wheels.InvalidArgument` throw — the helper is expecting a string.

That one call does a remarkable amount of work. By default the helper wraps the input in its label (`labelPlacement="around"` is the default), so it emits:

```html
<label for="user-email">Email<input type="email" name="user[email]" id="user-email" data-auto-id="user_email" value="dev@example.com" maxlength="255"></label>
```

Walk through what you didn't have to type:

- **`name="user[email]"`** — the bracket convention. On submit, Wheels parses `user[email]` into a nested struct, so the value arrives at `params.user.email`. That's the whole point: it round-trips.
- **`id="user-email"`** plus a `data-auto-id="user_email"` companion — auto-derived from `objectName` and `property` (dash-style for the `id`, underscore-style for `data-auto-id`), so the label's `for=` wires up automatically and E2E tests can target either form.
- **`value="dev@example.com"`** — read straight off `user.email`. No `value="#user.email#"` by hand.
- **`maxlength="255"`** — pulled from the column's `varchar` size. Free client-side guardrail.
- **`<label>Email</label>`** — derived from the property name, and the input lands *inside* it (the default `around` placement). Want the label as a separate sibling before the input? Pass `labelPlacement="before"`. (More on labels below.)

And if `user` has a validation error on `email`, the whole field wraps itself in your configured error element. You write one line; the framework writes the correct ten.

### Why the bracket name matters

This is the round-trip that makes the rest of Wheels feel coherent. A field helper emits `name="user[email]"`. On submit, the dispatcher turns that bracketed name into a nested struct — `params.user.email`. So when every field in your form binds to `objectName="user"`, the entire form arrives as one assembled `params.user` struct, and your controller does:

```cfm
// app/controllers/Users.cfc
function create() {
    user = model("User").new(params.user);  // params.user.firstName, .email, .age, ...
    if (user.save()) {
        redirectTo(route="user", key=user.id, success="User created");
    } else {
        renderView(action="new");  // re-render new.cfm; `user` now carries the errors
    }
}
```

`params.user` is the struct the form built. `model("User").new(params.user)` mass-assigns it. That's why create and update actions everywhere in Wheels reach for `params.<singularModelName>` — it's the other half of the binding you set up in the view. Bind the form to `user`, get `params.user` in the controller. They line up by convention, not by coincidence.

## A complete create/edit form

Let's build the whole thing. Here's `app/views/users/new.cfm` (and `edit.cfm` is nearly identical — I'll note the one difference):

```cfm
<!--- app/views/users/new.cfm --->
<cfparam name="user" default="">

#errorMessagesFor(objectName="user")#

#startFormTag(route="users", method="post")#

  #textField(objectName="user", property="firstName", label="First name")#
  #emailField(objectName="user", property="email", label="Email")#
  #telField(objectName="user", property="phone", label="Phone")#
  #numberField(objectName="user", property="age", min="0", max="120", label="Age")#
  #passwordField(objectName="user", property="password", label="Password")#

  #submitTag(value="Save")#
#endFormTag()#
```

Three things to point at.

**The `cfparam` at the top is not optional.** Your controller passes `user` to the view, but on a *failed* save you re-render `new.cfm` with the populated, errored object — and on the initial GET you might be rendering with nothing yet. `<cfparam name="user" default="">` guarantees the variable exists either way, so the field helpers don't blow up looking for a variable that isn't there. Cfparam every variable a controller hands a view. The form object included.

**`startFormTag` builds the action URL like `urlFor`.** You give it a `route` (or `controller`/`action`/`key`) and it constructs the `<form action="...">` for you. `endFormTag()` closes it. Between them, the helpers.

**`emailField`, `telField`, `numberField` are real, distinct helpers** — not `textField` with a `type` you typed by hand. `emailField` emits `type="email"`, `numberField` emits `type="number"` and accepts `min`/`max`/`step`. They bind exactly like `textField` — same `name="user[...]"`, same auto-id, same error wrapping — but with the right HTML5 input type baked in. Use them; that's what they're for.

### The edit form and the method override

For `edit.cfm`, the form needs to submit an update, which is semantically a PUT. So you'd write:

```cfm
#startFormTag(route="user", key=user.id, method="put")#
```

But here's the catch HTML hands you: **browsers can only submit `GET` and `POST`.** There is no real HTTP PUT from an HTML form. Wheels handles this transparently — `method="put"` (or `"patch"`, or `"delete"`) gets rewritten to `method="post"`, and a hidden field is injected:

```html
<input type="hidden" name="_method" value="put">
```

The dispatcher reads that `_method` field back on the way in and dispatches to your `update` action as if it were a real PUT. (The hidden field's `id` is stripped so you don't get duplicate `id="_method"` if there are multiple forms on the page.) The same override also fires automatically when the named route you're targeting has a non-GET verb.

This is exactly why you let the helper do it. Before a fix landed in the helper, those verbs were sometimes rendered verbatim onto the raw `<form>` — and the browser silently fell back to a GET submission, which leaks your CSRF token into the URL. So never hand-write `method="put"` on a literal `<form>` tag. Use `startFormTag` and let it rewrite. And speaking of CSRF: when protection is on and the effective method is `post`/`put`/`patch`/`delete`, `startFormTag` also appends a hidden `authenticityTokenField()` for you. One more thing off your plate.

## The HTML5 single-input helpers that exist

This is the part where it pays to know the actual roster, because guessing wrong gives you a runtime error and the wrong guesses are tempting. Here is the complete list of object-bound single-input helpers:

| Helper | Emits | Extra options |
|---|---|---|
| `textField` | `type="text"` (overridable) | `type` |
| `emailField` | `type="email"` | — |
| `urlField` | `type="url"` | — |
| `numberField` | `type="number"` | `min`, `max`, `step` |
| `telField` | `type="tel"` | — |
| `dateField` | `type="date"` | `min`, `max`, `step` |
| `colorField` | `type="color"` | — |
| `rangeField` | `type="range"` | `min`, `max`, `step` |
| `searchField` | `type="search"` | — |
| `passwordField` | `type="password"` | — |
| `hiddenField` | `type="hidden"` | — |
| `fileField` | `type="file"` | — |
| `textArea` | `<textarea>` | — |

That's it. **There is no `timeField`, no `dateTimeField` (or `datetimeLocalField`), no `monthField`, no `weekField`.** Reach for one and you get a "method does not exist" error. If you want dates or times as dropdowns instead of a single native input, Wheels has discrete `<select>`-based helpers — `dateSelect`, `timeSelect`, `dateTimeSelect` (object-bound) and `dateSelectTags`, `timeSelectTags`, `dateTimeSelectTags` (non-object) — but those are a different shape from the single HTML5 inputs and out of scope here.

A few behavioral notes on the roster:

- **`textField` is the one with an overridable `type`.** `textField(objectName="user", property="email", type="email")` is functionally `emailField`. The dedicated helpers exist so you don't have to remember the type string, but `textField`'s escape hatch is there for an exotic input type that lacks a dedicated helper.
- **`passwordField` pre-fills its value** from the bound property — there's no special masking on the server side. If you don't want the stored value echoed into the password input, don't store a plaintext password to begin with (you shouldn't), and pass `value=""` explicitly to be safe.
- **`fileField` does NOT pre-fill** — file inputs can't have a server-set value anyway. Pair it with `startFormTag(multipart=true)`, which sets `enctype="multipart/form-data"` for you.
- **`textArea` puts the value in the element content** (between its opening and closing tags), not in a `value` attribute — but everything else (name, id, error wrapping) is identical to `textField`.

### Selects, radios, and checkboxes

Beyond the single inputs, the multi-value helpers follow the same binding rules.

**`select`** binds the property to the matching `<option selected>`. Its `options` can be a query, an array of structs, a struct, or a comma list. Bind it to a foreign key and it's how you build an association picker:

```cfm
<cfparam name="user" default="">
<cfparam name="roles" default="">

#startFormTag(route="users", method="post")#
  #select(
      objectName="user",
      property="roleId",
      options=roles,
      valueField="id",
      textField="name",
      includeBlank="- Select role -",
      label="Role"
  )#
  #submitTag(value="Save")#
#endFormTag()#
```

`options=roles` is a query (model finders return queries, so `roles = model("Role").findAll()` in the controller). `valueField="id"` and `textField="name"` name the option's value and display columns. The option whose value equals `user.roleId` gets `selected`. `includeBlank="- Select role -"` adds a leading blank entry. One important subtlety: a single select uses **exact-match** comparison, so a stored value like `"Doe,John"` won't accidentally select a `"Doe"` option. Only `multiple=true` makes the bound value get treated as a comma list of selections.

**`radioButton`** takes a `tagValue` — the value when that specific radio is selected — and marks itself `checked` when the bound property equals it. Multiple radios for one property get unique ids (the id is suffixed with a slugified `tagValue`), so the labels still wire up.

**`checkBox`** is the one with a real HTML gotcha baked in, and it's worth a dedicated section.

## The unchecked-checkbox problem

Unchecked checkboxes don't post. That's not a Wheels quirk; it's how HTML forms work. If a checkbox is unchecked at submit time, the browser sends *nothing* for it — the param is simply absent. So a user who unchecks "Active" doesn't send `active=0`; they send no `active` key at all, and a naive `update` would leave the old value in place.

`checkBox` solves this with `uncheckedValue` — and crucially, **it defaults to one for you** (`checkedValue=1`, `uncheckedValue=0`), so the fix is on by default:

```cfm
<cfparam name="user" default="">
#startFormTag(route="users", method="post")#
  #checkBox(objectName="user", property="active", checkedValue="1", uncheckedValue="0", label="Active")#
  #submitTag(value="Save")#
#endFormTag()#
```

Because `uncheckedValue` is set (whether by the default or explicitly), the helper emits the checkbox *and* a companion hidden input named `user[active]($checkbox)` carrying the unchecked value. On submit, the dispatcher collapses that `($checkbox)` companion into the real `params.user.active` — but only when the checkbox itself didn't post. So a checked box posts `1`, an unchecked box posts `0` (via the companion), and `params.user.active` is always present. The only way back to the absent-param behavior is to explicitly pass `uncheckedValue=""` — then the box posts `1` when checked and nothing when unchecked.

One more checkbox subtlety: the `value` attribute is `checkedValue`, and the box is `checked` when the bound property equals `checkedValue`. If you set `checkedValue` *blank* (`checkedValue=""`), the box auto-checks when the bound value is numeric `1` or any value CFML reads as boolean-true (boolean `true`, or the strings `"true"`/`"yes"`). A column storing something CFML does not treat as boolean (e.g. `"active"` or `"on"`) will **not** auto-check. If your column stores anything other than `1`/boolean, set `checkedValue` explicitly.

## The non-model siblings: the `*Tag` helpers

Everything above is object-bound — it produces nested `params.<model>.<field>`. But plenty of forms aren't bound to a model: a search box, a filter bar, a login form. For those, every helper has a `Tag` variant — `textFieldTag`, `emailFieldTag`, `selectTag`, `searchFieldTag`, `checkBoxTag`, and so on.

The difference is the param shape. A `Tag` helper takes a flat `name` (and `value`) and emits a plain `name="<name>"` with **no brackets** — so it lands at `params.<name>`, flat, not nested:

```cfm
#startFormTag(action="search", method="get")#
  #searchFieldTag(name="q", value=params.q ?: "", label="Search")#
  #selectTag(
      name="category",
      options="Books,Music,Film",
      selected=params.category ?: "",
      includeBlank="- Any -"
  )#
  #submitTag(value="Go")#
#endFormTag()#
```

This submits as `?q=...&category=...`, arriving as `params.q` and `params.category` — flat. (Under the hood, the `Tag` helper synthesizes a one-key object `{q: value}` and delegates to the object helper, which is why the API feels identical — but the emitted name has no brackets.)

The rule of thumb: **object helpers when you have a model object and want `params.<model>.<field>`; Tag helpers for standalone fields where no model exists.** Don't reach for a Tag helper just to skip typing `objectName=` — the param shape is genuinely different and your controller code depends on it.

## Rendering errors

Two helpers, two jobs. Both return an empty string when the object is clean (not an error, just `""`), and both throw `Wheels.IncorrectArguments` in development if you hand them a variable that isn't an object.

**`errorMessagesFor`** is the summary block. It returns a `<ul class="error-messages">` listing every error across every property of the object, pulled from `object.allErrors()`. Drop it at the top of the form:

```cfm
#errorMessagesFor(objectName="user")#
```

By default it lists every message, including duplicates (`showDuplicates=true`); pass `showDuplicates=false` to collapse identical messages. Pass `includeAssociations=true` to fold in errors from nested objects. Clean object, empty string — so it's safe to leave in unconditionally.

**`errorMessageOn`** is the per-field, inline version. It returns the **first** error message on a single property, wrapped in the element and class you choose:

```cfm
<cfparam name="user" default="">

<div>
  #textField(
      objectName="user",
      property="email",
      label="Email",
      errorElement="p",
      errorClass="field-error"
  )#
  #errorMessageOn(objectName="user", property="email", wrapperElement="span", class="help-text")#
</div>
```

Two layers of error rendering are happening here, and they're independent. The **field itself** auto-wraps in `<p class="field-error">` when `user.email` has an error — that's the `errorElement`/`errorClass` arguments on the field helper, applied automatically whenever the bound property is invalid. The **`errorMessageOn`** call below prints the human-readable message text. Use them together: the field wrapper gives you the visual treatment (red border, whatever your CSS does with `.field-error`), and `errorMessageOn` prints what actually went wrong.

So you've got a choice of two error styles. `errorMessagesFor` at the top for a single consolidated list — the classic Rails-flavored "3 errors prevented this user from being saved" block. Or `errorMessageOn` next to each field for inline, field-adjacent messages. Or both. They don't conflict.

## On labels: there is no `label()` helper

Worth stating plainly because it's a natural thing to go looking for: **there is no standalone `label()` or `labelTag()` view helper.** Labels are a feature *of the field helpers*. You pass `label="..."`:

```cfm
#textField(objectName="user", property="firstName", label="First name")#
```

and the helper builds the `<label>` and wires its `for=` to the field's auto-derived id. You can control placement with `labelPlacement` (`"before"`, `"after"`, `"around"`, `"aroundLeft"`, `"aroundRight"`) — the default is `"around"`, so the input nests inside the label. `label="false"` suppresses the label entirely. And if you omit `label`, it defaults to deriving a label from the model property name — so `property="firstName"` becomes a sensible "First name" label without you saying so. The reason there's no freestanding helper is that the label's whole job is to wire `for=` to the field's id, and the field is the thing that owns that id.

## Sharp edges

The bugs that find you first, each one a real behavior of these helpers.

**Never mix positional and named arguments.** This is the single most common Wheels error, full stop. Object helpers are always named: `objectName="user", property="email"`. The moment you pass options, *everything* must be named — `textField("user", "email", label="X")` is a mix and will misbehave. All-named, every time.

**`objectName` is the variable name, not the object.** `objectName="user"` is a string; the helper resolves `variables["user"]` itself. Pass the instance (`objectName=user`) and you get `Wheels.InvalidArgument`. This trips up everyone exactly once.

**Cfparam the form object.** A failed save re-renders the form with the populated, errored object — but the field and error helpers all assume the variable exists. `<cfparam name="user" default="">` (or `default="#model('User').new()#"`) at the top of the view keeps a re-render from blowing up on a missing variable.

**`method="put"`/`"patch"`/`"delete"` is not a real HTTP verb.** It rewrites to POST plus a hidden `_method` field that the dispatcher reads back. Always go through `startFormTag` — hand-writing `method="put"` on a raw `<form>` makes the browser fall back to GET and leaks the CSRF token into the URL.

**The HTML5 roster is finite.** `emailField`, `urlField`, `numberField`, `telField`, `dateField`, `colorField`, `rangeField`, `searchField`, plus `textField` with a `type` override. There is no `timeField`, `dateTimeField`/`datetimeLocalField`, `monthField`, or `weekField`. For date/time-as-dropdowns, use `dateSelect`/`timeSelect`/`dateTimeSelect` (and the `*Tags` variants).

**Unchecked checkboxes are covered by default.** `checkBox` defaults to `checkedValue=1`/`uncheckedValue=0`, so a companion hidden `objectName[property]($checkbox)` input ensures a value always posts; the dispatcher substitutes it only when the box didn't post. Pass `uncheckedValue=""` explicitly and you opt back into the raw behavior where an unchecked box leaves the param absent.

**Blank `checkedValue` auto-checks on `1`, boolean `true`, or boolean-coercible strings like `"true"`/`"yes"`.** A value CFML does not read as boolean (e.g. `"active"`) won't auto-check — set `checkedValue` to whatever your column actually stores.

**A single `select` uses exact match, not list match.** A stored `"Doe,John"` won't accidentally select a `"Doe"` option. Only `multiple=true` treats the bound value as a comma list of selections.

**`Tag` helpers produce flat params, object helpers produce nested ones.** `searchFieldTag(name="q")` → `params.q`. `textField(objectName="user", property="email")` → `params.user.email`. Pick based on whether a model object exists, not on which is less typing — your controller depends on the shape.

**Field value precedence: object first, unless you override.** A field reads the bound property's value *only* when no `value` argument was passed (or the passed one is empty). Pass `value="..."` explicitly and it wins over the stored value. Useful for pre-seeding a form with something other than the persisted state — but easy to forget you did it when the field stops tracking the object.

**`errorMessageOn` is first-only; `errorMessagesFor` is all.** One property's first message versus a `<ul>` of everything. Both return `""` when clean, and both throw `Wheels.IncorrectArguments` in development if the named variable isn't an object.

## The whole loop

Pull it together and the round-trip is symmetric. The view binds every field to `objectName="user"`, so each emits `name="user[...]"`. The submit assembles those brackets into `params.user`. The controller does `model("User").new(params.user)` and `save()`. On failure it re-renders the same view with the same (now errored) `user` object — and because the fields read from the object and the error helpers read from the object, the form repopulates and the messages render with zero extra code. You wrote the field helpers once; they handle both the empty form and the errored re-render.

That symmetry is the reason to use the helpers over hand-rolled HTML. It's not that typing `<input name="user[email]" value="#user.email#">` is hard. It's that the helper gets the name, the id, the value, the maxlength, the label wiring, the error wrapping, the CSRF token, and the verb override all correct, all at once, every time — including on the re-render path where hand-rolled forms quietly lose the user's input. Let the framework write the form. It already knows how.
