---
title: 'Routing Deep-Dive: Resources, Nested Callbacks, and Route Model Binding'
slug: routing-resources-model-binding
publishedAt: '2026-06-30T14:00:00.000Z'
updatedAt: '2026-06-19T15:10:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - routing
  - resources
  - model-binding
categories: []
excerpt: >-
  A complete Wheels 4.0 routing guide — RESTful resources, nested resources
  via callback vs manual nested=true, and route model binding that resolves
  params.post before your action runs. Plus the sharp edges: route order, the
  protected-helper-names trap, and how a missing record 404s.
coverImage: null
---

Here's the line of code you write the same way in every controller you've ever built:

```cfm
function show() {
    post = model("Post").findByKey(params.key);
    if (!IsObject(post)) {
        renderText("Not found");  // ...or redirect, or throw, or forget entirely
        return;
    }
}
```

It's three lines. You write it in `show`, `edit`, `update`, and `delete` — four actions, four copies, in every resourceful controller in the app. The `findByKey` is mechanical. The not-found check is the part you forget, and the day you forget it `/posts/999999` hands a visitor a stack trace instead of a 404.

Wheels 4.0's router takes that boilerplate off your plate. You declare a resource once in `config/routes.cfm`, flip on *route model binding*, and the dispatcher resolves `params.post` into a real `Post` instance — and 404s a missing record — *before your action ever runs*. The action body shrinks to the part that's actually yours.

This post walks the modern routing surface end to end: RESTful `resources`, nesting (the callback form and the manual form, which behave differently), named routes, `root`, `wildcard`, and then the binding feature in depth. Along the way, the sharp edges — because routing is one of those subsystems where the order of two lines decides whether anything works.

## resources() is seven routes from one call

Start with the workhorse. One call:

```cfm
<cfscript>
mapper()
    .resources("posts")
.end();
</cfscript>
```

`.resources("posts")` registers the seven RESTful routes — `index`, `new`, `create`, `show`, `edit`, `update`, `delete` — each as a *named* route. The actual route registration is deferred: `resources()` just records the block, and `end()` materializes the routes. On a collection it adds `GET index` and `POST create`; the `new` form gets a `GET`; on a member it adds `edit`, `show`, `update`, and `delete`.

One detail that bites people reasoning about which route matched: **`update` registers two routes, not one** — a `PATCH` and a `PUT`, both pointing at the `update` action. So a `PUT /posts/42` and a `PATCH /posts/42` both dispatch to `update`. Don't assume a single verb when you're tracing a request.

Need a subset? `only` and `except` filter the action set:

```cfm
<cfscript>
mapper()
    .resources(name="posts", except="delete")          // six routes, no delete
    .resources(name="sessions", only="new,create,delete")
.end();
</cfscript>
```

A typo in `only` or `except` throws `Wheels.InvalidResource` — **but only when `showErrorInformation` is on**, which is every environment except production. In production the unknown action name is silently dropped. So `only="shwo,create"` looks fine on your prod box and quietly registers one fewer route than you meant. Catch it locally.

There's also a singular sibling, `resource()` (no `s`): no `[key]` in the URL and no `index` action — its action set is `new`, `create`, `show`, `edit`, `update`, `delete`. Use it for things you have exactly one of per context: `.resource("session")`, `.resource("profile")`. `resources()` is literally implemented by delegating into `resource()` (with a `$plural=true` flag that adds `index`), so the argument list is identical.

## Nesting: the callback form and the manual form

Nested resources are where the two forms diverge, and the difference is the single most common routing mistake. Get this one right and the rest is easy.

The **preferred** form passes a `callback`:

```cfm
<cfscript>
mapper()
    .resources(name="posts", callback=function(map){
        map.resources("comments");        // /posts/[key]/comments...
    })
.end();
</cfscript>
```

Passing a `callback` auto-enables nested mode. Inside the callback the parent member is on the scope stack, so `comments` nests under `/posts/[key]/comments` with prefixed route names. The thing to internalize: **you do NOT close the inner block.** The framework runs your callback and then calls `end()` for you, once. There is no `.end()` after the `comments` line and none inside the callback.

The **manual** form does the opposite:

```cfm
<cfscript>
mapper()
    .resources(name="posts", nested=true)
        .resources("comments")
    .end()                                // YOU close it
.end();
</cfscript>
```

`nested=true` *suppresses* the auto-`end()`, so the obligation flips to you — you must call `.end()` to close the nested block. Both produce the same routes. The trap is mixing them: a `callback` **plus** a manual `.end()` adds an extra `end()` that eventually pops a block that isn't there, and once the scope stack is empty that guarded `end()` throws `Wheels.InvalidRoute`. Pick one form. Use the callback form unless you have a reason not to — it's harder to get wrong because there's no `end()` to forget or duplicate.

Here's the rule in a table:

| Form | nested? | Who calls end()? |
|---|---|---|
| `.resources(name="posts", callback=fn)` | auto-on | the framework, once |
| `.resources(name="posts", nested=true)` … | on | **you** |
| `.resources("posts")` | off | the framework, immediately |

## Named routes, root, and the wildcard

`resources` covers REST. For everything else — login, a webhook receiver, a custom action — you write explicit routes with `get`, `post`, `put`, `patch`, and `delete`:

```cfm
<cfscript>
mapper()
    .get(name="login",         to="sessions##new")
    .post(name="authenticate", to="sessions##create")
.end();
</cfscript>
```

That `##` is not a typo and it's not optional. Inside a CFML double-quoted string, `#` is the expression delimiter — a literal single `#` would try to evaluate `sessions` as an expression. `##` is the CFML escape for a literal `#`. The router splits `to` on that single `#` into `controller` and `action`. So in real `.cfm` code you always write `to="sessions##new"`. If you give a `name` but no `pattern`, the pattern defaults to the hyphenized name; if there's no `[action]` in the pattern and you didn't pass one, the action defaults to the name.

`root()` maps `/`:

```cfm
<cfscript>
mapper()
    .root(to="home##index", method="get")
.end();
</cfscript>
```

Note `method="get"`. **`root()` defaults to GET only** unless you pass a method — that guard is deliberate, because a methods-less route would otherwise match *every* verb hitting `/`. If you omit `to` entirely, `root()` auto-targets `home##index` when `app/views/home/index.cfm` exists, falling back to the framework's welcome page otherwise.

`wildcard()` is the catch-all that maps generic `[controller]/[action]` and `[controller]` routes, so you don't have to register a route every time you add an action:

```cfm
<cfscript>
mapper()
    .wildcard()                       // [controller]/[action] and [controller]
.end();
</cfscript>
```

Like `root`, **`wildcard()` defaults to GET-only.** If you want it to cover all verbs (`get,post,put,patch,delete`), pass `method=""` — the empty string is the signal for "all verbs." Pass `mapKey=true` and it also maps `[controller]/[action]/[key]`.

And here's the rule that governs the whole file: **wildcard goes last.**

## Route order is load-bearing

When a request comes in, the dispatcher scans the registered routes *in registration order*, filtering by HTTP method, and stops at the first regex that matches. First match wins, full stop. There's no specificity ranking, no longest-prefix tiebreaker — whichever route you registered earliest and that matches the URL is the one that runs. (Static routes with no variables get an O(1) hash-lookup fast path, but the "first registered wins" semantics hold either way.)

The wildcard is greedy by design — it's built to match `anything/anything`. Register it early and it shadows every route below it: your carefully-named `login` route never gets a look-in because `wildcard` already claimed `/login` as `controller=login, action=index`. So the canonical order is:

```
MCP routes  →  resources  →  custom named routes  →  root  →  wildcard (LAST)
```

One wrinkle you'll see in a real app: the **shipped** `config/routes.cfm` actually lists `.wildcard()` *before* `.root()`. That's fine — `wildcard` doesn't match the bare `/`, so `root` still resolves. But it means the CLI scaffolds new routes at a `// CLI-Appends-Here` marker that sits above the wildcard, and **any explicit named route you add by hand must go above `.wildcard()`** or it's dead on arrival. Here's the shipped file:

```cfm
<cfscript>
mapper()
    // CLI-Appends-Here
    .wildcard()
    .root(method = "get")
    .end();
</cfscript>
```

Add your `.get(name="login", ...)` above the `.wildcard()` line, not below it.

## A realistic routes file

Putting the pieces together — an API scope with binding, nested resources via callback, a limited resource, named auth routes, root, wildcard last:

```cfm
<cfscript>
mapper()
    // API scope: binding=true cascades to every nested resource
    .scope(path="/api", name="api", binding=true)
        .resources("products")            // params.product on show/edit/update/delete
    .end()

    // Nested resources via callback (no inner .end() needed)
    .resources(name="posts", binding=true, callback=function(map){
        map.resources("comments");        // /posts/[postKey]/comments...
    })

    // Limit the generated REST actions
    .resources(name="sessions", only="new,create,delete")

    // Custom named routes BEFORE the wildcard so they aren't shadowed
    .get(name="login",         to="sessions##new")
    .post(name="authenticate", to="sessions##create")

    .root(to="home##index", method="get")

    .wildcard()   // keep LAST: matches [controller]/[action] generically
.end();
</cfscript>
```

Two things in there earn their own sections: `scope()` and that `binding=true` flag.

## Scopes, namespaces, and grouping

`.scope()` pushes a frame onto the scope stack. Its `path`, `name`, `package`, `constraints`, `middleware`, and `binding` all combine with the parent frame, so everything nested inside inherits them. The `/api` scope above prefixes every route's URL with `/api`, prefixes the route names with `api`, and — because of `binding=true` — turns on route model binding for every resource it contains.

There's a small family of these:

| Helper | What it adds |
|---|---|
| `.scope(...)` | the general form — path + name + package + constraints + middleware + binding |
| `.namespace(name, package, path)` | a package and a URL path |
| `.group(name, path, constraints, callback)` | pure name/path/constraint grouping, no package |
| `.api(path="api", name="api", ...)` | shorthand for `group(path="api", name="api")` |
| `.version(number, ...)` | a `v1` path/name prefix |

`scope()`, `namespace()`, `package()`, `controller()`, `group()`, `api()`, and `version()` all auto-close via `end()` when you pass a `callback` — same convention as the resource callback. Only the no-callback form of `.scope()` needs a manual `.end()`.

## Route model binding: the part that earns its keep

Back to the boilerplate from the top of the post. Route model binding makes it disappear.

Flip it on per-route:

```cfm
<cfscript>
mapper()
    .resources(name="posts", binding=true)
.end();
</cfscript>
```

Now look at what the controller becomes:

```cfm
// app/controllers/Posts.cfc
component extends="Controller" {
    function config() {
        super.config();
    }

    // GET /posts/[key]  ->  params.post is pre-resolved by route model binding
    function show() {
        // params.post is already a Post instance.
        // If key 999 didn't exist, dispatch threw Wheels.RecordNotFound (404)
        // BEFORE this method was ever entered.
    }
}
```

No `findByKey`. No not-found check. The dispatcher resolves the binding during param construction — *after* the route matches but *before* the controller is instantiated — so by the time `show()` runs, either `params.post` is a real instance or the request already 404'd.

How does it know to call it `params.post`? Convention: `binding=true` resolves the model by singularizing then capitalizing the controller name (`posts` → `Post`) and stores the instance under the lower-camel singular (`params.post`). Controller `categories` → model `Category` → `params.category`.

The view side is one line — **`cfparam` the binding key, and make sure it's the right key**:

```cfm
<!--- app/views/posts/show.cfm --->
<cfparam name="post" default="">
<h1>#post.title#</h1>
<p>#post.body#</p>
```

Get the key wrong (`<cfparam name="posts">` plural, say) and the variable you actually reference is undefined.

### Explicit model names

When the controller name and the model name don't line up, name the model explicitly:

```cfm
<cfscript>
mapper()
    // Convention: controller `posts` -> model `Post` -> params.post
    .resources(name="posts", binding=true)

    // Explicit override: controller `writers`, but bind the Author model -> params.author
    .resources(name="writers", binding="Author")

    .wildcard()
.end();
</cfscript>
```

`binding="Author"` stores the instance under `params.author` — the lower-camel of the *model* name, not the controller. `cfparam name="author"` in the `writers` views.

### Binding cascades down the scope stack

Binding inherits. Set it on a scope and every resource and named route underneath it is bound, without `binding` ever appearing on their own calls:

```cfm
<cfscript>
mapper()
    .scope(path="/api", binding=true)
        .resources("products")           // bound -> params.product
        .resources("orders")             // bound -> params.order
    .end()
.end();
</cfscript>
```

This is the convenience, and also the gotcha: a route can be bound without the word `binding` anywhere near its line. If you're surprised a record is being resolved, look up the scope stack.

### The global switch

Want it everywhere? One line in `config/settings.cfm`:

```cfm
set(routeModelBinding=true);
```

That turns on binding for **every** route that has a `key` param and doesn't set its own per-route binding. Per-route binding overrides the global in *both* directions — including off. `binding=false` on a specific route wins even when the global switch is on, so you can opt one resource out of an otherwise-global policy.

## How a miss behaves — and where it differs

The happy path is clean. The failure paths have nuance worth knowing before you wrap anything in a `try/catch`.

**A missing record always 404s** — but the *exception* is dev-only. When the bound key doesn't resolve to a row, the dispatcher routes through the framework's 404 handler, which *always* sets HTTP status 404. In any non-production environment (`showErrorInformation` on) it then throws the typed `Wheels.RecordNotFound` exception so you see exactly what happened. In **production** it renders `onmissingtemplate.cfm` and aborts — no typed exception. So:

- The HTTP outcome is 404 in every environment.
- `Wheels.RecordNotFound` is the exception type surfaced in every non-production environment.
- **Do not** write a `try/catch` around your action expecting to catch `Wheels.RecordNotFound` in production — it isn't thrown there.

**A missing model *class* is a different failure, and the two binding forms diverge on it.** This is the subtle one:

| Scenario | `binding=true` (convention) | `binding="ModelName"` (explicit) |
|---|---|---|
| Model class can't be resolved | silently **skipped**, negative-cached | **re-throws** (treated as a config error) |
| Bound record (row) is missing | 404 (`Wheels.RecordNotFound` in dev) | 404 (`Wheels.RecordNotFound` in dev) |

The reasoning: an explicit `binding="Author"` is a promise — you *named* a model, so if it can't be found that's a misconfiguration worth surfacing loudly. A convention `binding=true` is a best-effort guess off the controller name; if the controller has no matching model class, the framework shrugs, skips binding, and negative-caches the result in `application.wheels.unresolvableRouteBindings` so it doesn't re-attempt the failed model bootstrap on every single request. (That cache clears on reload.) Either way, a genuinely missing *record* — as opposed to a missing class — always 404s. And finder/DB query errors always propagate; they're never swallowed.

When binding is *off* but a route looks like a binding candidate (it has a `key` and a member action — `show`, `edit`, `update`, or `delete`), the framework emits a one-time dev-only log hint suggesting you might want it on. Free nudge, no runtime cost in production.

## The sharp edge that has nothing to do with binding: protected action names

This one surprises everyone exactly once. You write a perfectly reasonable controller action and it 404s, and you can't figure out why because the route is right there in `wheels routes`.

```cfm
// app/controllers/Pages.cfc
component extends="Controller" {

    // WRONG: `model` is a public framework helper. A request to /pages/model
    // throws Wheels.ActionNotAllowed (-> 404); this body never runs.
    function model() { /* unreachable as an action */ }

    // WRONG too: redirectTo, linkTo, env, isGet/isPost/isAjax/..., flash
    // helpers are all reserved the same way.
    function redirectTo() {}

    // RIGHT: standard REST names are not helpers, so they dispatch fine.
    function index() {}
    function show()  {}

    // RIGHT: any non-helper name works.
    function dashboard() {}
}
```

Here's the mechanism. At app start, the framework scans the live metadata of every public, non-`$`-prefixed helper mixed onto controllers — from `wheels.Global`, `wheels.controller.*`, and `wheels.view.*` (so `env`, `model`, `redirectTo`, `linkTo`, the `is*` request predicates, the flash helpers, all of them) — and builds `application.wheels.protectedControllerMethods`. On dispatch, `$callAction()` checks the requested action name: if it's in that list (or starts with `$`), the framework throws `Wheels.ActionNotAllowed`, which surfaces as a 404. The action is never reached.

The net effect: **you cannot name a controller action after any framework helper.** The good news is the list is built dynamically from component metadata, not hard-coded — so it always tracks exactly what helpers exist, and the seven standard REST action names (`index`, `show`, `new`, `edit`, `create`, `update`, `delete`) are *not* helpers, so they're never affected. If a custom action 404s and the route looks correct, check whether you've named it after a helper. Rename it.

## Sharp edges, collected

Everything above, distilled into the list to keep next to your keyboard:

- **Route order is everything.** First matching route in registration order wins; the scan `break`s on the first hit. Keep `wildcard()` last; put explicit named routes above it (above the `// CLI-Appends-Here` marker's wildcard in the shipped file).
- **Callback nesting vs `nested=true` are opposites.** A `callback` auto-calls `end()` for you (don't add one). `nested=true` suppresses the auto-`end()` (you must add one). Mixing them leaves an extra `end()` that pops an empty scope stack and throws `Wheels.InvalidRoute`.
- **`update` is two routes** — PATCH and PUT — both → `update`.
- **`to="x##y"` needs the `##` escape** inside CFML string literals; a literal single `#` is an expression delimiter.
- **`root()` and `wildcard()` are GET-only by default.** Pass `method`/`methods` (or `method=""` on wildcard for all verbs) to widen them.
- **`only`/`except` typos throw everywhere except production.** In production an unknown action name is silently dropped — your route count is quietly wrong.
- **Binding inherits down the scope stack.** `.scope(path="/api", binding=true)` binds everything nested under it without `binding` appearing on those lines.
- **Convention binding skips a missing model class; explicit binding re-throws.** A missing *record* always 404s either way.
- **`Wheels.RecordNotFound` is thrown in every non-production environment** (wherever `showErrorInformation` is on). Production sets 404 and renders the missing-template page — don't `try/catch` for the typed exception in prod.
- **`cfparam` the binding key under the right name** — lower-camel singular of the *model* (`params.post`, `params.blogPost`), not the controller.
- **You can't name an action after a framework helper** (`model`, `redirectTo`, `linkTo`, `env`, the `is*` predicates, flash helpers). It 404s via `Wheels.ActionNotAllowed`. Standard REST names are safe.

## Wrap-up

Routing in Wheels 4.0 is two ideas working together. `resources` (plus the scoping family and named routes) declares the *shape* of your URLs in one readable file, where the only real discipline is keeping `wildcard` last. Route model binding then removes the most-copied four lines in any resourceful controller — the `findByKey` plus the not-found check — by resolving `params.post` and 404-ing a missing record before your action runs.

Turn binding on per-resource while you're learning its failure modes (the convention-vs-explicit divergence, the dev-only exception), then reach for the global `set(routeModelBinding=true)` once it's second nature. Your `show` action drops to the part that was ever actually yours.
