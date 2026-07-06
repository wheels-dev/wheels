---
title: 'Associations Deep-Dive: hasMany, belongsTo, Nested Properties, and Eager Loading'
slug: associations-deep-dive-wheels-4
publishedAt: '2026-07-03T14:00:00.000Z'
updatedAt: '2026-06-19T15:10:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - models
  - associations
  - orm
categories: []
excerpt: >-
  A comprehensive Wheels 4.0 guide to model associations — hasMany, belongsTo,
  and hasOne, the exact dynamic methods each one generates, dependent-delete
  cascades, nested properties from form params, eager loading with include=,
  has-many-through, and polymorphic associations — with the sharp edges that
  bite in practice.
coverImage: null
---

You build the blog. A `Post` model, an `Author` model, a `Comment` model. Then the requests start. The author page needs every post that author wrote. The post page needs every comment, but only if the comment belongs to *that* post. Deleting an author shouldn't orphan a hundred posts pointing at a dead foreign key. The admin form lets you edit a post and add three comments in the same submit. The index page renders 50 posts with their author's name, and you do not want 51 queries to do it.

Every one of those is a join, a foreign key, and a lifecycle rule. You *could* write them by hand — `findAll(where="authorId = #author.id#")` here, a manual `DELETE FROM posts WHERE authorId = ?` there, a hand-rolled loop to save the nested comments. People do. And then six months later the FK column gets renamed, the cascade gets forgotten on one of the four delete paths, and the nested form silently drops the second comment because the loop had an off-by-one.

Associations are the part of the ORM that turns all of that into declarations. You say `hasMany("comments")` once, in `config()`, and Wheels gives you the getter, the counter, the builder, the cascade, and the eager-load join — all named by convention, all generated at app start. This post walks every association type, the exact methods each one generates, how nested properties let a parent save its children, and how `include=` collapses the N+1 into one query. Then the sharp edges, because there are a few that will absolutely bite you.

## The three association types

There are three. Everything else is a flavor of one of them.

- **`belongsTo`** — this model holds the foreign key. A `Post` *belongs to* an author, so `posts.authorId` exists. This is the "child" side.
- **`hasMany`** — the foreign key lives on the *other* table, and there are many of them. An `Author` *has many* posts; the `authorId` lives over on `posts`. This is the "parent, one-to-many" side.
- **`hasOne`** — same as `hasMany` (the FK is on the other table) but exactly one. An `Author` *has one* profile; `profiles.authorId` exists, but there's only ever one row.

All three are declared inside `config()` and nowhere else. Here's a model that uses all of them — `app/models/Author.cfc`:

```cfm
component extends="Model" {
    function config() {
        hasMany("posts");        // FK authorId lives on the posts table
        hasOne("profile");       // FK authorId lives on the profiles table
        belongsTo("user");       // FK userId lives on THIS (authors) table
    }
}
```

And the child side — `app/models/Post.cfc`:

```cfm
component extends="Model" {
    function config() {
        belongsTo("author");     // posts.authorId
        hasMany("comments");     // comments.postId
    }
}
```

Notice the symmetry: `Author hasMany("posts")` and `Post belongsTo("author")` describe the *same* relationship from the two ends. You declare both sides. Wheels does not infer one from the other.

### Conventions, and when to override them

When you write `belongsTo("author")`, Wheels deduces three things from the single `name` argument:

- **modelName** — singularize and PascalCase the name → `Author`. The model file is `app/models/Author.cfc`.
- **foreignKey** — `author` + `Id` → `authorId`. The column on `posts`.
- **joinKey** — the related table's primary key, `id`.

For `hasMany("posts")` the same logic runs the other direction: the model is `Post`, and the foreign key it looks for is `authorId` *on the posts table* (named after the model declaring the association, not the association name).

When your schema doesn't follow the conventions, override the pieces by passing named arguments. This is the moment to be careful about argument style — Wheels functions **cannot mix positional and named arguments**, which is the single most common error against this API. The instant you pass *one* option, *every* argument must be named:

```cfm
// WRONG — positional name + named option. Errors.
belongsTo("user", foreignKey="ownerId");

// RIGHT — all named once you pass any option
belongsTo(name="user", foreignKey="ownerId", joinKey="ownerId");

// RIGHT — positional-only is fine when there are NO options
belongsTo("user");
```

Same rule for `hasMany` and `hasOne`. `hasMany("comments")` is fine. `hasMany("comments", dependent="delete")` is an error. `hasMany(name="comments", dependent="delete")` is correct.

## The methods each association generates

This is the payoff, and it's where the factsheet gets concrete. Each association call registers a fixed set of dynamic methods on the model. They aren't real methods on your `.cfc` — they're matched at runtime through `onMissingMethod` against the association's method list — but they behave exactly like methods you wrote.

A `belongsTo` is the smallest. It generates exactly two:

| Method | Returns |
|---|---|
| `post.author()` | the related Author object (or `false`) |
| `post.hasAuthor()` | boolean — is the FK set and the row present |

A `hasOne` generates seven — the getter, existence check, plus the lifecycle verbs for the single related row:

| Method | Effect |
|---|---|
| `author.profile()` | the related Profile (or `false`) |
| `author.hasProfile()` | boolean |
| `author.newProfile(...)` | unsaved Profile, FK pre-set |
| `author.createProfile(...)` | saved Profile |
| `author.setProfile(obj)` | point the relationship at an object |
| `author.removeProfile()` | NULL the FK on the related row |
| `author.deleteProfile()` | delete the related row |

A `hasMany` generates eleven — the plural getter, a count, an existence check, a singular finder, and the full add/create/delete/remove surface in both single-record and bulk forms. For `Author hasMany("posts")`:

| Method | Effect |
|---|---|
| `author.posts()` | **query** of related posts (see the next gotcha) |
| `author.postCount()` | numeric count |
| `author.hasPosts()` | boolean |
| `author.findOnePost()` | a single Post |
| `author.newPost(...)` | unsaved Post, `authorId` pre-set |
| `author.createPost(...)` | saved Post |
| `author.addPost(post=obj)` *or* `addPost(key=id)` | point an existing post's FK at this author |
| `author.removePost(key=id)` | NULL that post's `authorId` |
| `author.deletePost(post=obj)` | delete that post |
| `author.removeAllPosts()` | bulk `UPDATE posts SET authorId = NULL` |
| `author.deleteAllPosts()` | bulk `DELETE` of all related posts |

The naming is mechanical and worth internalizing: singular verbs (`newPost`, `addPost`, `removePost`, `deletePost`, `findOnePost`, `postCount`) use the **singularized** association name; the bulk verbs (`removeAllPosts`, `deleteAllPosts`, `hasPosts`) use the **plural**. So with `hasMany("comments")` you get `post.commentCount()`, `post.addComment()`, `post.hasComments()`, `post.removeAllComments()`.

Here it is exercised end to end:

```cfm
author  = model("Author").findOne(order="id");

posts   = author.posts();                          // query of related posts
n       = author.postCount();                      // numeric
any     = author.hasPosts();                       // boolean
first   = author.findOnePost();                    // single Post object

newPost = author.newPost(title="Draft");           // unsaved, authorId already set
made    = author.createPost(title="T", body="B");  // saved

author.addPost(post=existingPost);                 // or addPost(key=existingPost.id)
author.removePost(key=p.id);                       // NULLs that post's authorId
author.deletePost(post=p);                         // deletes that post
author.removeAllPosts();                           // UPDATE ... SET authorId = NULL
author.deleteAllPosts();                           // DELETE all related posts
```

The `add`/`remove`/`delete` singular methods take **either** an object (passed as the singular association name — `addPost(post=...)`) **or** a `key=` argument holding the primary key. Use whichever you have in hand.

### The getter returns a query, not an array

`author.posts()` looks like it should hand you an array of Post objects. It does not. The `hasMany` getter delegates to `findAll`, and `findAll` returns a **query object** by default. This is the #2 source of association bugs, right behind mixed arguments. Loop it as a query:

```cfm
<!--- RIGHT --->
<cfloop query="posts">
    #posts.title#
</cfloop>

<!--- WRONG — there is no array to loop --->
<cfloop array="#posts#" index="post">
    #post.title#
</cfloop>
```

If you genuinely want objects to iterate — say you need to call instance methods on each post — pass `returnAs="objects"` through the getter, since it forwards its arguments to `findAll`:

```cfm
postObjects = author.posts(returnAs="objects");
```

But for views, the query is faster and the query loop is the idiom. Reach for objects only when you need them.

## Cascading deletes: the `dependent` argument

When you delete an author, what happens to their posts? By default, nothing — the rows stay, now pointing at an author that no longer exists. That's a dangling foreign key waiting to surface as a bug. The `dependent` argument on `hasMany` and `hasOne` tells Wheels what to do.

There are **exactly five** legal values, and this is the spot where people reach for one that doesn't exist:

```cfm
function config() {
    hasMany(name="comments", dependent="delete");     // instantiate each child + delete (runs callbacks)
    hasMany(name="logs",     dependent="deleteAll");  // bulk DELETE, no instantiation, no callbacks
    hasMany(name="tasks",    dependent="remove");     // instantiate each child + set FK to NULL
    hasMany(name="notes",    dependent="removeAll");  // bulk UPDATE FK = NULL, no instantiation
    hasMany(name="orphans",  dependent=false);        // default — do nothing on parent delete
}
```

The two axes are *what* and *how*:

- **`delete` / `deleteAll`** remove the child rows entirely.
- **`remove` / `removeAll`** keep the rows but NULL their foreign key, detaching them from the parent.
- The **`All`** variants (`deleteAll`, `removeAll`) run as a single bulk SQL statement — fast, but they **bypass object instantiation**, so per-child `beforeDelete`/`afterDelete` callbacks do not fire.
- The non-`All` variants (`delete`, `remove`) instantiate each child first, so their callbacks **do** run. Slower, but correct if a child needs to clean up after itself (delete an uploaded file, decrement a counter cache, whatever).

There is **no `nullify` value.** If you came from another ORM expecting `dependent="nullify"`, the Wheels equivalent is `remove` (instantiated) or `removeAll` (bulk). The validation happens lazily: the value is *stored* at declaration without complaint, and the framework throws `Wheels.InvalidArgument` only when you actually delete a parent and Wheels tries to cascade. The error message names the four verbs plus `false` so you can fix it on the spot:

```cfm
hasMany(name="comments", dependent="nullify");   // config() is fine; author.delete() later throws Wheels.InvalidArgument
```

One more thing the factsheet is explicit about: **`belongsTo` has no `dependent` argument.** A `Post` belongs to an author, but the post doesn't *own* the author — there's nothing to cascade upward. Passing `dependent` to `belongsTo` isn't a supported option; the cascade lives only on the side that owns the related records.

## Nested properties: save the parent and its children in one shot

Here's the admin-form scenario. You're editing an author, and the same form has fields for the author's profile. You submit once. You want the author *and* the profile to save together, from one `params` struct, with one `.save()` call.

That's `nestedProperties`. It must be declared **after** the association it names, because it looks that association up at registration time — declare it before, and you get `Wheels.AssociationNotFound`.

```cfm
// app/models/Author.cfc
component extends="Model" {
    function config() {
        hasOne("profile");
        hasMany("posts");
        nestedProperties(association="profile", allowDelete=true);
    }
}
```

Now a `params.author` struct that contains a nested `profile` key flows straight through:

```cfm
// In AuthorsController.cfc
function update() {
    author = model("Author").findByKey(params.key);
    author.update(params.author);   // saves the author AND its nested profile
}
```

Two defaults matter:

- **`autoSave` defaults to `true`.** Simply enabling `nestedProperties` on an association means its children save automatically when the parent saves. You don't call anything extra. (Pass `autoSave=false` if you want to enable nesting for mass-assignment whitelisting but handle the save yourself.)
- **`allowDelete` defaults to `false`.** You must opt in for deletion-via-form to work. With `allowDelete=true`, a nested child whose params contain a truthy boolean `_delete` value gets deleted when the parent saves — the classic "remove this row" checkbox in a repeating form.

`nestedProperties` accepts a comma-list of associations (and `association` is aliased as `associations`, so both spellings work):

```cfm
nestedProperties(associations="profile,posts", allowDelete=true);
```

Two more arguments are worth knowing. `sortProperty` reorders `hasMany` children by a numeric, 1-based property — useful when the form lets you drag rows into an order. `rejectIfBlank` is a list of properties that must be present in the nested params or the nested CRUD for that child is skipped entirely — your guard against a half-filled "add another" row creating an empty record.

It also white-lists the association name for mass assignment if you've set up a whitelist, so the nested struct isn't rejected as an unexpected key.

## Eager loading: kill the N+1 with `include=`

The index page renders 50 posts, each showing its author's name. The naive version calls `post.author()` inside the loop — one query for the posts, then one more per post for the author. 51 queries. This is the N+1, and `include=` is the fix. It eager-loads the association via a SQL JOIN, so the whole thing is one query.

```cfm
// One query, author joined in
posts = model("Post").findAll(include="author");
```

Multiple direct associations? Comma-list them:

```cfm
posts = model("Post").findAll(include="author,comments");
```

`findOne` takes the same `include`:

```cfm
author = model("Author").findOne(order="id", include="user");
```

`findOne` is smart about it: with no include, or an include of a non-`hasMany` association (a `belongsTo` or `hasOne`), it optimizes to `maxRows=1`. But when you include a `hasMany`, one parent row multiplies into many joined rows, so `findOne` falls back to pagination (`page=1`, `perPage=1`) to dedupe back down to a single parent. You don't manage this — just know that an included `hasMany` is doing more work under the hood.

### Nested includes need `returnAs="query"`

To join associations *on already-included models*, use parentheses. An album has an artist, the artist has a genre:

```cfm
rows = model("Album").findAll(include="artist(genre)", returnAs="query");
```

The hard constraint: **complex (parenthesized) includes only work when `returnAs="query"`.** When you're returning objects, you may only include **direct** associations of the current model. Try to combine a parenthesized include with object return and `returnIncluded=true`, and Wheels throws an "Incorrect Arguments" error. So:

```cfm
// OK — direct associations, returning a query (the default)
model("Post").findAll(include="author,comments");

// OK — nested, but returnAs must be query
model("Album").findAll(include="artist(genre)", returnAs="query");

// THROWS — nested include while returning objects
model("Album").findAll(include="artist(genre)", returnAs="objects");
```

One quiet helpful behavior: when `page` is set together with an `include`, Wheels automatically adds `DISTINCT` so the joined `hasMany` rows don't inflate your page counts.

## Many-to-many: has-many-through

A reader subscribes to many publications; a publication has many readers. The relationship is stored in a join table, `subscriptions`. You model it with a plain `hasMany` to the join, plus a `shortcut` that gives you a dynamic method reaching *through* the join to the far side. The join model (`Subscription`) carries its own `belongsTo("publication")` so the chain has something to follow.

```cfm
// app/models/Reader.cfc
component extends="Model" {
    function config() {
        hasMany(name="subscriptions", shortcut="publications");
    }
}
```

Now `reader.publications()` returns a query of publications across the join — Wheels expands the through-chain into the parenthesized include form automatically before running the query.

The `shortcut` is the new method name. The companion `through` argument is a two-item list naming the chain from the *far* side back to this model — and you only need to set it when the association names differ from the model names. Its default is `singularize(shortcut), name`, which is why the simple case above needs no `through` at all. When you do need it:

```cfm
// Custom chain when the join's belongsTo name doesn't match the shortcut
hasMany(name="subscriptions", shortcut="magazines", through="publication,subscriptions");
```

Like every other `hasMany` getter, the shortcut returns a **query**, not an array. Loop it as one.

## Polymorphic associations

A `Comment` can belong to a `Photo` *or* an `Article` — the same comments table, attached to different parent types. That's a polymorphic association. The child stores two columns: a foreign key *and* a type column naming which model owns the row.

The child side uses `polymorphic=true`:

```cfm
// app/models/Comment.cfc
component extends="Model" {
    function config() {
        belongsTo(name="commentable", polymorphic=true);
    }
}
```

That expects a `commentableId` and a `commentableType` column on `comments`. The type column holds the owning model's name (e.g. `"Photo"`), and Wheels resolves the actual model per row at runtime — which is why `modelName` is left blank on a polymorphic `belongsTo`.

The parent side uses `as=`, matching the interface name:

```cfm
// app/models/Photo.cfc  (and the same in Article.cfc)
component extends="Model" {
    function config() {
        hasMany(name="comments", as="commentable");   // matches commentableId + commentableType
    }
}
```

Resolution is through the dynamic getter — the type column drives which model loads, per row:

```cfm
comment = model("Comment").findOne(where="commentableType='Photo'");
parent  = comment.commentable();      // a Photo object, resolved at runtime
exists  = comment.hasCommentable();   // boolean
```

The catch — and it's a real one — **a polymorphic `belongsTo` cannot be eager-loaded.** Because the target model varies row to row, there's no single table to JOIN against. `findAll(include="commentable")` throws `Wheels.PolymorphicIncludeNotSupported`. Resolve polymorphic parents one at a time through the dynamic method instead:

```cfm
// THROWS Wheels.PolymorphicIncludeNotSupported
model("Comment").findAll(include="commentable");

// Do this instead — per-row resolution
<cfloop query="comments">
    <cfset c = model("Comment").findByKey(comments.id)>
    <cfset parent = c.commentable()>
</cfloop>
```

## Sharp edges

The factsheet flags a handful of things that look right and aren't. Memorize these — every one of them is a real, cited behavior.

- **Mixed argument styles error.** `hasMany("comments", dependent="delete")` mixes a positional name with a named option and throws. The moment you pass any option, name *everything*: `hasMany(name="comments", dependent="delete")`. Positional-only (`hasMany("comments")`) is fine.

- **Getters return queries, not arrays.** `author.posts()` and `findAll(include=...)` hand you a query object by default. Loop with `<cfloop query="posts">`, not `array=`. Pass `returnAs="objects"` to the getter only when you actually need objects.

- **`dependent` has no `nullify`.** The five legal values are `delete`, `deleteAll`, `remove`, `removeAll`, and `false`. FK-nulling is `remove` (instantiated) / `removeAll` (bulk). Anything else throws `Wheels.InvalidArgument` — but only when you delete a parent and the cascade runs, not at declaration. And the `All` variants skip per-child callbacks — use the non-`All` form when a child needs its delete callbacks to run.

- **`belongsTo` takes no `dependent`.** It doesn't own the related records, so there's nothing to cascade. Only `hasMany` and `hasOne` accept `dependent`.

- **Join types default differently per association type.** `belongsTo` joins with `INNER JOIN`; `hasMany` and `hasOne` join with `LEFT OUTER JOIN`. This matters when you include a `belongsTo`: with the default inner join, parent rows that have *no* matching child are **silently dropped** from the result. If a post might have no author and you still want the post, pass `joinType="outer"` on the `belongsTo`.

- **Nested includes are query-only.** Parenthesized includes like `include="artist(genre)"` require `returnAs="query"`. Returning objects with a parenthesized include throws — when returning objects you may include only direct associations.

- **`nestedProperties` must come after its association.** Declare it before the `hasMany`/`hasOne`/`belongsTo` it references and you get `Wheels.AssociationNotFound`. Also remember `autoSave` defaults to `true` (children save with the parent automatically) and `allowDelete` defaults to `false` (you must opt in before `_delete` does anything).

- **Polymorphic `belongsTo` can't be eager-loaded.** `findAll(include="commentable")` throws `Wheels.PolymorphicIncludeNotSupported`. Use `comment.commentable()` per row. The type column value must exactly match the parent's model name, and the parent side declares `as="commentable"` to match the child's `commentableId`/`commentableType` columns.

- **has-many-through needs `shortcut`.** A plain `hasMany` doesn't fetch the far side of a many-to-many by itself — you need `shortcut` (the new method name) and, only if the names diverge from the models, `through`. The default `through` is `singularize(shortcut),name`.

## Putting it together

Here's a worked, end-to-end slice. A `Post` belongs to an author, has many comments (cascade-deleted with their callbacks), and accepts comments nested from the edit form.

```cfm
// app/models/Post.cfc
component extends="Model" {
    function config() {
        belongsTo("author");
        hasMany(name="comments", dependent="delete");
        nestedProperties(association="comments", allowDelete=true);
    }
}
```

The controller — note the private filter, and a `cfparam` for every variable the view will read:

```cfm
// app/controllers/Posts.cfc
component extends="Controller" {
    function config() {
        filters(through="loadPost", only="show,edit,update,delete");
    }

    function index() {
        // One query: posts with their authors joined in (no N+1)
        posts = model("Post").findAll(include="author", order="createdAt DESC");
    }

    function show() {
        comments = post.comments();          // query of related comments
        commentCount = post.commentCount();  // numeric
    }

    function update() {
        // Saves the post AND any nested comment params in one call,
        // deleting any whose _delete flag is set
        if (post.update(params.post)) {
            redirectTo(route="post", key=post.id);
        } else {
            renderView(action="edit");
        }
    }

    private function loadPost() {
        post = model("Post").findByKey(params.key);
    }
}
```

The index view loops the result **as a query** and reads the joined author column off the same query — no second trip to the database:

```cfm
<!--- app/views/posts/index.cfm --->
<cfparam name="posts" default="">

<cfloop query="posts">
    <h2>#posts.title#</h2>
    <p>by #posts.firstName# #posts.lastName#</p>
</cfloop>
```

The whole feature is six declarations and a query loop. The FK lookups, the cascade on delete, the nested save, the join that avoids the N+1 — all of it falls out of `belongsTo`, `hasMany`, `nestedProperties`, and `include=`. That's the trade associations make: you describe the relationships once, in `config()`, and the framework writes the SQL, the lifecycle, and a couple dozen dynamic methods you never have to maintain.
