---
title: 'Validations Beyond Presence: Conditional Rules, Custom Validators, and Enum Integration'
slug: validations-conditional-enum
publishedAt: '2026-07-01T14:00:00.000Z'
updatedAt: '2026-06-19T15:10:00.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - validations
  - models
categories: []
excerpt: >-
  A practical Wheels 4.0 guide to the full validation surface — conditional
  rules with condition/unless/when, custom validate() methods, enum()
  integration, and how to read the error API correctly. Built end-to-end
  around one User model, with every behavior grounded in the framework source.
coverImage: null
---

The first validation everyone writes is `validatesPresenceOf("email")`. It's the right first move — most bugs in a young app are "we let a row in with a missing field." But presence is the floor, not the ceiling, and the day you ship a real signup form you discover the floor isn't enough.

You need the email to *look* like an email. You need it unique — but only within an account, because two different tenants can both have a `support@` address. You need a password to match its confirmation field, but only on create, because the edit form doesn't ask for the password again. You need a discount reason, but only when there's actually a discount. And you need `status` to be one of `draft`, `published`, `archived` — never `wat`.

None of that is presence. All of it ships in Wheels 4.0's model layer, and most of it is one line in `config()`. This post walks the whole surface — the high-level validators, conditional firing with `condition`/`unless`/`when`, custom `validate()` methods, and `enum()` — through one worked `User`/`Post` model, and it ends with the part everyone gets wrong: reading the errors back out.

## The validator surface

Every high-level validator is a single call in your model's `config()`. Here's the full set, applied to one model, so you can see them side by side:

```cfm
// app/models/User.cfc
component extends="Model" {
    function config() {
        // presence: the floor. Comma-list fans out to one check per property.
        validatesPresenceOf(properties="firstName,lastName,email");

        // uniqueness, narrowed to an account, skipped when blank
        validatesUniquenessOf(property="email", scope="accountId", allowBlank=true,
            message="That email is already registered");

        // format via a built-in type, and via a raw regex
        validatesFormatOf(property="email", type="email", allowBlank=true);
        validatesFormatOf(property="phone", regEx="^\d{3}-\d{3}-\d{4}$", allowBlank=true);

        // length: `within` is a two-value (min,max) list
        validatesLengthOf(property="username", within="3,20");

        // numericality with bounds
        validatesNumericalityOf(property="age", onlyInteger=true,
            greaterThanOrEqualTo=18, allowBlank=true);

        // inclusion / exclusion — `list` is REQUIRED on both
        validatesInclusionOf(property="role", list="member,editor,admin");
        validatesExclusionOf(property="username", list="admin,root,system",
            message="[property] is reserved");

        // confirmation: needs a virtual passwordConfirmation property
        validatesConfirmationOf(property="password", caseSensitive=true);
    }
}
```

That's nine validators and the entire registration surface for this model. Each one maps to a behavior worth knowing precisely:

| Validator | What it checks | Default message |
|---|---|---|
| `validatesPresenceOf` | Property missing, blank simple value (`Len==0`), or empty struct | `[property] can't be empty` |
| `validatesUniquenessOf` | No other row has the same value (a `findAll()` per record) | `[property] has already been taken` |
| `validatesFormatOf` | `regEx` doesn't match (`ReFindNoCase`), or `IsValid(type, value)` is false | `[property] is invalid` |
| `validatesLengthOf` | String length vs `exactly` / `maximum` / `minimum` / `within` | `[property] is the wrong length` |
| `validatesNumericalityOf` | Not strictly numeric, or violates `onlyInteger` / `odd` / `even` / comparison bounds | `[property] is not a number` |
| `validatesInclusionOf` | Value not in the required `list` | `[property] is not included in the list` |
| `validatesExclusionOf` | Value *is* in the required `list` | `[property] is reserved` |
| `validatesConfirmationOf` | `<property>Confirmation` is missing or differs | `[property] should match confirmation` |

A few of these have edges that bite the first time:

**`validatesUniquenessOf` is an application check, not a database constraint.** It runs a `findAll()` against the table to see whether any *other* row already holds the value (on update it disregards the current record by comparing the existing object's `key()` against the record's persisted key). That means two concurrent requests can both pass the check and both insert — a classic race. Back it with a real unique index for correctness; treat the validator as the thing that gives the user a clean error message, not the thing that guarantees uniqueness. It also costs one extra query per validated record.

The `scope` argument is the part people miss. It's a comma-list of additional properties that narrow the uniqueness window. `scope="accountId"` means "unique email *per account*" — exactly what you want for multi-tenant data.

**`validatesFormatOf` has two modes.** Pass `regEx` for an arbitrary pattern (matched with `ReFindNoCase`), or pass `type` for a built-in `IsValid()` check. The supported types are `creditcard`, `date`, `email`, `eurodate`, `guid`, `social_security_number`, `ssn`, `telephone`, `time`, `URL`, `USdate`, `UUID`, `variableName`, `zipcode`, and `boolean`. An unsupported `type` throws `Wheels.IncorrectArguments` — it's validated at registration when error information is on, so you find out at app start, not at request time.

**`validatesLengthOf` treats `within` as authoritative.** Give it `"3,20"` and it's cleaned to `[min, max]` and overrides `minimum`/`maximum`. All the bare bounds default to `0`, and a `0` bound is treated as "not set" — the check only fires when the bound is truthy. So `minimum=0` does nothing; you can't use it to require a non-empty string (use `validatesPresenceOf` for that).

**`validatesInclusionOf` and `validatesExclusionOf` both require `list`.** Omit it and the call errors. Inclusion fails when the value is *not* in the list (`ListFindNoCase`); exclusion fails when it *is*. Reserved-username checks are the canonical exclusion use; closed-set fields are the canonical inclusion use — and inclusion is exactly what `enum()` registers under the hood, which we'll get to.

**`validatesConfirmationOf` puts the error somewhere surprising.** It compares `password` against a virtual companion property named `passwordConfirmation` — `<property>` + `Confirmation`. That companion is never persisted; it exists only for the comparison. The failure is case-insensitive `!=` by default, and `caseSensitive=true` adds a `Compare()` pass on top. The catch: the error lands on the *confirmation* property, not the base one. To read it you call `errorsOn("passwordConfirmation")`, and your form needs an actual `passwordConfirmation` field for the user to type into.

### The `property` vs `properties` thing

You'll notice the suite above mixes `property=` and `properties=`. Both work, and both feed the same slot. The first argument on *every* high-level validator is `properties` (plural) — a comma-list. The singular `property` is an alias that `$registerValidation` merges in, and a comma-list fans out into one registered validation per property. CLAUDE.md's convention is "`property` for a single value, `properties` for a list," but mechanically they resolve identically. Use whichever reads better; just be consistent.

### `allowBlank` and the floor

`allowBlank` is the argument that makes a layered model clean instead of noisy. It exists on exclusion, format, inclusion, length, numericality, and uniqueness — and it defaults to `false` everywhere. When `true`, the validation is skipped if the value is blank or absent, so a missing email gets *one* error ("can't be empty" from `validatesPresenceOf`) instead of three ("can't be empty," "is invalid," "has already been taken"). That's why the suite above pairs `validatesPresenceOf(properties="...email...")` with `validatesFormatOf(property="email", ..., allowBlank=true)`: presence owns the empty case, format owns the malformed case, and they don't double up.

Two validators do *not* accept `allowBlank`: `validatesPresenceOf` (it *is* the blank check — `allowBlank` would be a contradiction) and `validatesConfirmationOf` (it always compares).

## Conditional validation: condition, unless, when

The next thing real forms demand is "validate this, but only sometimes." Wheels gives you three knobs.

`when` controls *which lifecycle phase* a validation fires in. It takes `onSave` (the default — both create and update), `onCreate`, or `onUpdate`. `condition` and `unless` control *whether* a validation fires at all, based on the object's current state.

```cfm
component extends="Model" {
    function config() {
        // only require a discount reason when discount > 0
        validatesPresenceOf(property="discountReason", condition="this.discount > 0");

        // skip the slug check entirely for drafts
        validatesPresenceOf(property="slug", unless="this.isDraft()");

        // run the uniqueness check only at creation; never re-check on edits
        validatesUniquenessOf(property="sku", when="onCreate");

        // word-form comparison operators parse too
        validatesPresenceOf(property="approverId", condition="this.status eq 'pending'");
    }

    // condition/unless can call any public model method as a boolean
    boolean function isDraft() {
        return this.status == "draft";
    }
}
```

Here is the single most important thing to internalize about `condition` and `unless`: **they are string expressions, not closures, and they are not run through CFML's `Evaluate()`.** They go through a bespoke parser (`$evaluateConditionString`) that supports a fixed grammar and nothing else:

- `this.property` — read a property
- `this.method()` — call a model method (with or without args: `this.method(a='1', b='2')`)
- a bare `method()` — same, and you can negate it with `!method()`
- binary comparisons using `eq` / `neq` / `lt` / `lte` / `gt` / `gte`, or the symbolic `==` / `!=` / `<` / `<=` / `>` / `>=`

`condition` runs the validation when the expression evaluates true; `unless` runs it when the expression evaluates false. If you supply both, both must agree for the validation to run.

Because it's a hand-written parser and not `Evaluate()`, you can't drop arbitrary CFML in there. An expression outside the grammar throws `Wheels.InvalidValidationCondition` in development — so you catch the typo immediately — but in production an unparseable expression is logged and skipped, which means the validation *silently does not run*. Test your conditional expressions before you ship them; a production-only skip is a security-shaped bug waiting to happen.

`when` deserves its own note. `validatesUniquenessOf` defaults to `onSave`, which means it re-runs that extra `findAll()` on *every* update — even when the value never changed. For an immutable field like a SKU or an invite code, scope it to `when="onCreate"` and save yourself a query per edit.

## Custom validators: validate(), validateOnCreate(), validateOnUpdate()

When a rule needs real logic — cross-field comparisons, a lookup, "this can't change after signup" — you register a *method name* and let that method add the error itself.

```cfm
// the pattern mirrors vendor/wheels/tests/_assets/models/User.cfc,
// whose custom validators are public (bare `function`) methods
component extends="Model" {
    function config() {
        validate("checkEmailDomain");           // runs on create AND update
        validateOnCreate("ensureInviteCode");    // create only
        validateOnUpdate("preventEmailChange");  // update only
    }

    // a custom validator signals failure by ADDING an error; its return is ignored
    function checkEmailDomain() {
        if (Len(this.email) && !this.email contains "@company.com") {
            addError(property="email", message="must be a company address", name="domain");
        }
    }

    function ensureInviteCode() {
        if (!Len(this.inviteCode)) {
            addErrorToBase(message="An invite code is required to sign up");
        }
    }

    function preventEmailChange() {
        if (this.hasChanged("email")) {
            addError(property="email", message="cannot be changed after signup");
        }
    }
}
```

The mechanics are worth spelling out because they trip people up:

- `validate()` registers a method by *name* (a comma-list is allowed; the singular `method` is accepted too). It runs on both create and update. `validateOnCreate()` and `validateOnUpdate()` hard-wire `when` to `onCreate` / `onUpdate` and do *not* accept a `when` argument. None of these three take a `properties` argument — they're whole-object hooks, not property validators. They do accept `condition` and `unless`.
- **The method's return value is ignored.** A custom validator fails by *calling* `addError()` or `addErrorToBase()`. Returning `false` does nothing. This is the single biggest gotcha — a method that does `return false` when the data is bad will never produce an error.
- `addError(property, message, name)` attaches an error to a specific property. `addErrorToBase(message, name)` attaches an object-wide error (its `property` is `""`). Use base errors for "this combination of fields is wrong" situations that don't belong to one field.
- The optional `name` argument tags an error so you can find or clear it later — `clearErrors(property="email", name="domain")` removes just that one without touching the others.

One convention note: write these validator methods as **public** — that's how the framework's own test model declares them (a bare `function`, which is public by default in CFML). They live directly on your model component, not in a controller, so a public name here won't accidentally become a routable action the way a public controller method would.

## enum(): closed-set fields without the boilerplate

A `status` field with three legal values is one of the most common shapes in any app, and writing it by hand means three pieces of bookkeeping:

```cfm
function config() {
    validatesInclusionOf(properties="status", list="draft,published,archived");
    // ...plus you hand-write scopes and "is this a draft?" checkers elsewhere
}
```

`enum()` collapses all of it into one call:

```cfm
// app/models/Post.cfc
component extends="Model" {
    function config() {
        // comma-list form: the name IS the stored value
        enum(property="status", values="draft,published,archived");

        // struct form: name -> stored value (handy for integer columns)
        enum(property="priority", values={low: 0, medium: 1, high: 2});

        // enum's inclusion check uses allowBlank=true, so add presence yourself
        // if the column is mandatory:
        validatesPresenceOf(property="status");
    }
}
```

That single `enum()` call has three side effects:

1. **It auto-registers `validatesInclusionOf`** on the property, with the stored values as the list — and crucially with `allowBlank=true`. So `status="bogus"` fails validation cleanly, but a *blank* status passes by default. If the column is required, pair `enum()` with your own `validatesPresenceOf` (as above).
2. **It generates `is<Name>()` boolean checkers** via `onMissingMethod` — `post.isDraft()`, `post.isPublished()`, `post.isHigh()`. For the struct form, the checker compares against the *stored* value, so `isHigh()` is true when `priority == 2` (the stored value mapped to `high`).
3. **It registers one query scope per name** — `model("Post").published().findAll()`, `model("Post").high().findAll()` — using a parameterized `WHERE`, so the values are bound, not string-interpolated.

In use:

```cfm
// boolean checkers (onMissingMethod)
post.isDraft();   // true when status == "draft"
post.isHigh();    // true when priority == 2 (the stored value for "high")

// scopes, one per enum name — finders return query objects, loop accordingly
publishedPosts = model("Post").published().findAll();
urgentPosts    = model("Post").high().findAll();
```

The struct form (`{low: 0, medium: 1, high: 2}`) is the one to reach for when the column is an integer or you want the human-facing name to differ from what's persisted.

Two registration-time guards keep you honest. The property name must be a valid identifier or `enum()` throws `Wheels.InvalidPropertyName`. And stored values are restricted to the character set `[A-Za-z0-9_- .]` — so `"in-progress"` is fine, but `"in/progress"` throws `Wheels.InvalidEnumValue` at `config()` time. These fire at app start, which is exactly where you want a config error to surface.

Out-of-range values fail the auto-registered inclusion check like any other:

```cfm
var p = model("Post").new(status="bogus");
p.valid();                        // false
p.errorsOn("status")[1].message;  // "status is not included in the list"
```

## Running validations and reading errors

You almost never call `valid()` directly. `save()` runs the *identical* validation pipeline automatically — `valid()` exists for the check-without-saving case (a preview, a multi-step wizard, an API that wants to report errors before committing). Both clear existing errors, fire the `beforeValidation` callbacks, run the appropriate `onSave`/`onCreate`/`onUpdate` checks for whether the record is new, then fire `afterValidation`. `valid()` returns a boolean; `save()` returns `false` and leaves the errors populated when validation fails.

```cfm
// UsersController.cfc — controller filters stay private; this is a public action
function create() {
    user = model("User").new(params.user);
    if (user.save()) {            // runs the full validation pipeline for you
        redirectTo(route="user", key=user.key());
    } else {
        renderView(action="new"); // re-render with errors attached to `user`
    }
}
```

If you genuinely need to skip validation — a data migration, a trusted import — `save(validate=false)` bypasses it.

Now the part everyone gets wrong. **`errorsOn()` returns an array of error structs, not an array of strings.** Each element is `{property, message, name}`. Print the element directly in a view and you'll dump a struct onto the page. You have to read `.message`:

```cfm
<!--- app/views/users/new.cfm --->
<cfparam name="user" default="">

<cfif IsObject(user) AND user.hasErrors(property="email")>
    <ul class="errors">
        <cfloop array="#user.errorsOn('email')#" index="e">
            <li>#e.message#</li>
        </cfloop>
    </ul>
</cfif>
```

The full error-reading surface:

| Method | Returns | Notes |
|---|---|---|
| `errorsOn(property, name)` | array of `{property, message, name}` structs | read `.message` off each element |
| `errorsOnBase(name)` | array of structs | object-wide errors added via `addErrorToBase` |
| `allErrors(includeAssociations)` | array of all error structs | pass `true` to recurse into associations |
| `hasErrors(property, name)` | boolean | optional filters; bare call = "any errors at all?" |
| `errorCount(property, name)` | numeric | optional filters |
| `clearErrors(property, name)` | void | no args wipes everything; filtered removes only matches |

In a controller, the same API drives your branching:

```cfm
var user = model("User").new(params.user);
if (!user.valid()) {                          // same checks save() would run
    if (user.hasErrors(property="email")) {
        for (var err in user.errorsOn("email")) {
            writeOutput(err.message);          // .message — not the bare struct
        }
    }
    // object-wide errors from addErrorToBase:
    for (var err in user.errorsOnBase()) {
        writeOutput(err.message);
    }
    // or grab everything at once:
    var all = user.allErrors();                // array of {property, message, name}
}
```

The `name` tag you optionally pass to `addError` pays off here: `clearErrors(property="email", name="domain")` surgically removes the company-domain error your custom validator added, while leaving the format error from `validatesFormatOf` in place. Without the tag you'd have to clear all email errors and re-run.

### Custom messages and interpolation

Default messages use `[property]` interpolation — `"[property] can't be empty"` becomes `"Email can't be empty"`, with `[property]` replaced by the humanized label. You override the whole thing per validator with `message=`:

```cfm
validatesPresenceOf(property="email", message="We need an email to reach you");
validatesExclusionOf(property="username", list="admin,root", message="[property] is reserved");
```

Two interpolation tricks: `[[property]]` emits a literal `[property]` (escape hatch when you actually want the brackets), and `#expr#` message interpolation pulls values from the object's scope, so you can write messages like `"must be at least #arguments.minimum# characters"`.

## A worked end-to-end model

Pulling the threads together — here's a `User` model that uses presence, scoped uniqueness, format, length, numericality, inclusion, exclusion, confirmation, a conditional rule, a lifecycle-scoped rule, and a custom validator:

```cfm
// app/models/User.cfc
component extends="Model" {
    function config() {
        belongsTo("account");

        // the floor
        validatesPresenceOf(properties="firstName,lastName,email,role");

        // email: scoped-unique per account + valid format, both blank-tolerant
        validatesUniquenessOf(property="email", scope="accountId",
            allowBlank=true, message="That email is already registered");
        validatesFormatOf(property="email", type="email", allowBlank=true);

        // username: length-bounded, not a reserved word
        validatesLengthOf(property="username", within="3,20");
        validatesExclusionOf(property="username", list="admin,root,system",
            message="[property] is reserved");

        // role is a closed set
        validatesInclusionOf(property="role", list="member,editor,admin");

        // age only matters for the membership tier; only check it when present
        validatesNumericalityOf(property="age", onlyInteger=true,
            greaterThanOrEqualTo=18, allowBlank=true);

        // password confirmation, case-sensitive, only on signup
        validatesConfirmationOf(property="password", caseSensitive=true,
            when="onCreate");

        // an invite code is required, but only for free-tier accounts
        validatesPresenceOf(property="inviteCode",
            condition="this.isFreeTier()");

        // custom: enforce the corporate domain for the admin role
        validate("checkAdminDomain");
    }

    boolean function isFreeTier() {
        return this.tier == "free";
    }

    function checkAdminDomain() {
        if (this.role == "admin" && Len(this.email) && !this.email contains "@company.com") {
            addError(property="email", message="admins must use a company address",
                name="adminDomain");
        }
    }
}
```

Every line there is a verified Wheels 4.0 capability. The model reads top-to-bottom like a spec: required fields, a per-account-unique well-formed email, a bounded non-reserved username, a closed-set role, a conditional adult age, a signup-only confirmed password, a conditional invite code, and a custom cross-field rule for admins. The controller calls `user.save()`, branches on the boolean, and the view loops `user.errorsOn("email")` reading `.message`. That's the whole loop.

## Sharp edges

The things that will actually cost you an afternoon:

- **Never mix positional and named args.** `validatesPresenceOf("name", message="Required")` throws — it's the single most common Wheels error. The moment you pass an option, go all-named: `validatesPresenceOf(properties="name", message="Required")`. Positional-only with no options (`validatesPresenceOf("name")`) is fine.
- **`errorsOn()` returns structs, not strings.** Loop and read `.message`. Printing the element directly dumps a struct into your HTML.
- **A custom validator's return value is ignored.** It fails by calling `addError()` / `addErrorToBase()`. `return false` does nothing — the record will save.
- **`condition`/`unless` are a fixed-grammar string parser, not `Evaluate()` and not a closure.** Only `this.prop`, `this.method()`, bare `method()`, `!negation`, and the `eq/neq/lt/lte/gt/gte` (or symbolic) comparisons parse. A bad expression throws in development but is *logged and silently skipped in production* — so the validation quietly stops running. Test conditional expressions before you ship.
- **`validatesUniquenessOf` is not a database constraint.** It's an application-level `findAll()`; two concurrent requests can both pass and both insert. Add a real unique index. It also issues one extra query per validated record — scope it to `when="onCreate"` for immutable fields.
- **`validatesPresenceOf` is silently skipped on columns with a non-empty DB default** when the property isn't set on the object — the framework assumes the default will fill it. Don't rely on presence validation to catch a missing value on a column that carries a `columndefault`.
- **`validatesConfirmationOf` adds its error on the *virtual* `<property>Confirmation`**, not the base property. Read it with `errorsOn("passwordConfirmation")`, and add an actual `passwordConfirmation` field to your form.
- **`allowBlank` defaults to `false` everywhere it exists, and doesn't exist on `validatesPresenceOf` or `validatesConfirmationOf`.** Add `allowBlank=true` to format/length/numericality/inclusion/exclusion/uniqueness checks that should defer to presence for the empty case — otherwise a missing field produces a pile of redundant errors.
- **`enum()` permits a blank value by default** — its auto-registered inclusion check uses `allowBlank=true`. If the column is mandatory, pair `enum()` with `validatesPresenceOf`.
- **`enum()` stored values are restricted to `[A-Za-z0-9_- .]`.** `"in-progress"` is fine; `"in/progress"` throws `Wheels.InvalidEnumValue` at `config()` time. Property names must be valid identifiers (`Wheels.InvalidPropertyName` otherwise).
- **`validatesInclusionOf` and `validatesExclusionOf` require `list`.** Omitting it errors.
- **`validatesLengthOf` treats a `0` bound as "not set."** `minimum=0` does nothing; use `validatesPresenceOf` to require a non-empty value, and `within="3,20"` (which overrides `minimum`/`maximum`) for a range.

Presence is where you start. Everything above is what separates a form that *looks* validated from a form that actually is — conditional rules so you validate the right things at the right time, custom methods for logic the built-ins can't express, `enum()` for closed sets without the boilerplate, and an error API you read correctly the first time.
