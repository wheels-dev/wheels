---
title: 'Validation conditions now fail closed: migrating your 2.x condition strings'
slug: from-2x-to-41-validation-conditions
publishedAt: '2026-10-09T21:00:00.000Z'
updatedAt: '2026-10-06T00:55:34.000Z'
author: Peter Amiri
tags:
  - wheels-4
  - upgrade
  - migration
  - validation
categories:
  - Tutorials
excerpt: >-
  Part 5 of "From 2.x to 4.x: the field guide". CFWheels 2.x ran validation
  condition= and unless= strings through Evaluate(); Wheels 4.1 parses a small
  grammar and throws Wheels.InvalidValidationCondition for what it can't
  parse. This post lists the grammar 4.1.2 accepts, runs ten 2.x-style strings
  on 4.1.2 (three throw, seven give the wrong answer without an error),
  rewrites each one, covers the this.method() escape hatch and the two
  production conditions from the 4.1.1 CHANGELOG, and explains what Wheels 4.2
  changes.
coverImage: null
announcement:
  discussionUrl: 'https://github.com/wheels-dev/wheels/discussions/4541'
  title: "From 2.x to 4.x, part 5: validation conditions now fail closed"
  body: |
    New post: **[Validation conditions now fail closed: migrating your 2.x condition strings](https://blog.wheels.dev/posts/from-2x-to-41-validation-conditions/)** — 2.x ran `condition=` and `unless=` strings through Evaluate(); 4.1 parses a small grammar and throws for what it can't parse. The grammar, and how to migrate your strings.
---

CFWheels 2.x handed every `condition=` and `unless=` string to CFML's `Evaluate()`. Any expression the engine could run was accepted. Wheels 4.1 and later don't do that. It parses a small, fixed grammar, and since 4.1.0 a string it can't parse throws `Wheels.InvalidValidationCondition` instead of skipping the rule. This post covers what 4.1.2 accepts, what it does with the rest, and how we rewrote real 2.x condition strings and tested them on the example app.

## What changed, release by release

- **2.5.1** ran `Evaluate(arguments[local.item])` on each string. If that failed, it swapped `==`, `!=`, `<` and the rest for `eq`, `neq`, `lt` and so on, and tried again.
- **3.0** replaced `Evaluate()` with a parser. When parsing failed, it returned `false`, which quietly skipped the validation.
- **4.0.6** threw `Wheels.InvalidValidationCondition` when `showErrorInformation` was on, as it is in development. In production it logged the error and still skipped the rule.
- **4.1.0** made that path fail closed: an unparseable condition throws even when `showErrorInformation` is off ([#3398](https://github.com/wheels-dev/wheels/pull/3398)).
- **4.1.1** widened the grammar to cover what 4.1.0 had started rejecting: `&&`/`||`, parentheses, and a whitelist of read-only functions ([#3634](https://github.com/wheels-dev/wheels/issues/3634), fixed in [#3636](https://github.com/wheels-dev/wheels/pull/3636)).

The CHANGELOG's upgrade note puts it plainly: treat the 4.1 upgrade as "the moment previously-inert validations start being enforced". A condition that throws is an HTTP 500 on the save that triggers it.

## The grammar 4.1.2 accepts

- `this.property` and `this.method()`, with named (`key='val'`) or positional (`'val'`) arguments.
- A bare zero-argument call on the model: `isNew()`, `!isNew()`.
- Comparisons with `eq neq lt lte gt gte` or `== != < <= > >=`. The right-hand side is a literal: a number, or a string with or without quotes.
- `&&` and `||` (`&&` binds tighter), `!`, and parentheses.
- These functions only: `StructKeyExists`, `IsNull`, `IsNumeric`, `IsSimpleValue`, `IsStruct`, `IsArray`, `IsBoolean`, `IsDate`, `Len`, `ListFind`, `ListFindNoCase`, `ListContains`, `ListContainsNoCase`. Their arguments can be `this`, `this.x`, quoted strings, numbers or booleans.

Anything else is either rejected or, in a few shapes, read the wrong way. That second group is the one to worry about.

## What 4.1.2 does with 2.x strings

We took ten 2.x-style strings and ran each one on 4.1.2 under Lucee 7. Three come from the 2.5.1 docs: the guide's `condition="not isLoggedIn()"` and `unless="this.name is 'Ben Forta'"`, and the API reference's `unless="DayOfWeek() eq 1"`. The other seven are representative shapes we wrote, not taken from a real app. Each spec calls `$evaluateCondition()`, the check `valid()` runs before each rule:

| 2.x string | Record | On 4.1.2 |
|---|---|---|
| `condition="not isLoggedIn()"` | logged out | throws |
| `condition="Len(password)"` | any | throws |
| `condition="IsDefined('this.discountCode')"` | any | throws |
| `unless="this.name is 'Ben Forta'"` | name is Ben Forta | rule runs anyway |
| `unless="DayOfWeek() eq 1"` | any day | rule runs every day |
| `condition="status != 'draft'"` | a draft | rule runs anyway |
| `condition="isActive"` | active | rule skipped |
| `condition="isActive eq"` | active | rule skipped |
| `condition="this.kind eq 'b2b' and this.country eq 'SE'"` | Swedish B2B | rule skipped |
| `condition="this.total gt this.limit"` | total 50, limit 10 | rule skipped |

The three that throw are the easy ones, because the error names the problem:

```
The `condition` expression `Len(password)` could not be evaluated: Unsupported argument `password` in a condition function call. Supported arguments are `this`, `this.property`, `this.method()`, quoted strings, booleans and numbers — a bare variable name is not resolved (use `this.password`).
```

The other seven raise no error. They give the wrong answer:

- **A bare name on the left is compared as text.** `status != 'draft'` compares the word `status` with `draft`, so the rule always runs. `DayOfWeek()` is compared as the text `DayOfWeek()`.
- **Fewer than three tokens evaluates to `false`.** `isActive` and `isActive eq` skip the rule whatever the record holds.
- **After `this.`, unknown words become part of the operand.** `is` isn't an operator, so `this.name is 'Ben Forta'` looks up a property literally named `name is 'Ben Forta'`, finds nothing and returns `false`. With `and`, everything after the first `eq` becomes one string on the right-hand side, so `this.kind` is compared with `b2b and this.country eq SE`. A `this.` reference on the right is compared as the text `this.limit`.

## Rewrites

Each rewrite below is a rule in [`app/models/ConditionDemo.cfc`](https://github.com/wheels-dev/cfwheels-example-app/blob/series/post5/app/models/ConditionDemo.cfc), and a spec runs it through `valid()` both ways.

```cfm
// 2.x: condition="not isLoggedIn()", unless="this.name is 'Ben Forta'"
validatesPresenceOf(property="captcha", condition="!isLoggedIn()", unless="this.name eq 'Ben Forta'");

// 2.x: condition="status != 'draft'"
validatesPresenceOf(property="publishedAt", condition="this.status != 'draft'");

// 2.x: condition="isActive"
validatesPresenceOf(property="activatedBy", condition="this.isActive");

// 2.x: condition="Len(password)"
validatesConfirmationOf(property="password", condition="Len(this.password)");

// 2.x: condition="this.kind eq 'b2b' and this.country eq 'SE'"
validatesPresenceOf(property="vatNumber", condition="this.kind eq 'b2b' && this.country eq 'SE'");

// 2.x: condition="IsDefined('this.discountCode')"
validatesFormatOf(property="discountCode", regEx="^[A-Z0-9]{6}$", condition="StructKeyExists(this, 'discountCode')");
```

The rule of thumb: put `this.` on every property, use `&&`, `||` and `!` rather than `and`, `or` and `not`, use `eq` rather than `is`, and keep `this.` on the left of a comparison.

## The escape hatch

When the grammar can't express a rule, such as arithmetic, a function outside the whitelist, or comparing two properties, move it into a model method and call that:

```cfm
// 2.x: unless="DayOfWeek() eq 1"
validatesFormatOf(property="email", regEx="^.*@.*\.se$", condition="ipCheck()", unless="this.isSunday()");
validatesPresenceOf(property="reviewNote", condition="this.needsCheck()");

public boolean function needsCheck() {
    return StructKeyExists(this, "total") && IsNumeric(this.total) && this.total > 1000 && !isSunday();
}
```

The method is plain CFML, so `this.total gt this.limit` becomes `this.total > this.limit` inside it. The 2.x `DayOfWeek()` example needed rewriting anyway: on Lucee 7, `Evaluate("DayOfWeek()")` fails with "To few Attributes in function [DAYOFWEEK]", because the function needs a date.

## The two production cases in the CHANGELOG

The 4.1.1 upgrade note quotes two conditions from one production app:

```cfm
condition="StructKeyExists(this, 'requestFor') && this.requestFor == 'Engine Part'"
condition="ListFind('24,32,63,67,117,167,191', this.countryId)"
```

On 4.1.0 the first threw on every save and the second was silently inert. Both run unchanged from 4.1.1, and our spec checks each one both ways on 4.1.2. If you're still on 4.1.0, these two shapes are the reason to move to 4.1.1 or later.

## What Wheels 4.2 changes

[#3929](https://github.com/wheels-dev/wheels/pull/3929), merged to `develop` for Wheels 4.2 and not in 4.1.2, changes how a string that isn't a `this.` reference, a call or a whitelisted function is read. In 4.2:

- A bare name, alone or on the left of a comparison, resolves as `this.<name>` when the record has that property or method, and throws when it doesn't. `condition="isActive"` and `condition="status != 'draft'"` will work as written.
- A bare word on the right stays a string literal, numbers and `true`/`false` are typed, and a lone `true` or `false` is its own value.
- A `this.` reference on the right of such a comparison, or the wrong number of tokens, throws.

We ran our spec against that version of `validations.cfm`: `isActive eq` and `DayOfWeek() eq 1` throw, and `isActive` and `status != 'draft'` give the intended answer. #3929 leaves the `this.` path unchanged, though. `this.name is 'Ben Forta'`, the `and` form and `this.total gt this.limit` still give the same wrong answers, so rewrite those whatever version you're on. Wheels 4.2 throws on them too ([#3970](https://github.com/wheels-dev/wheels/pull/3970), for [#3964](https://github.com/wheels-dev/wheels/issues/3964)): a right-hand `this.`, word-form `and`/`or`, and operators such as `is`. A condition you leave unchanged will then fail loudly instead of quietly.

The [4.1 validation guide](https://guides.wheels.dev/v4-1-0/basics/validation-and-errors/) uses `this.status != 'draft'` and lists the grammar 4.1.2 accepts; the [4.2 guide](https://guides.wheels.dev/v4-2-0/basics/validation-and-errors/) describes the bare-name change.

## The example app

The example app has two conditions, `unless="isAuthenticated()"` and `condition="StructKeyExists(this, 'updatePassword')"`. Both parse on 4.1.2 unchanged, as [Pass 2](https://blog.wheels.dev/blog/from-2x-to-41-pass-2-upgrade-check) showed, so [1661b3c](https://github.com/wheels-dev/cfwheels-example-app/commit/1661b3c94addcdda5f9d042b9097fe0675067bf7) adds the demo model and `tests/specs/models/ConditionMigrationSpec.cfc`: 24 specs, all passing on Lucee 7. We didn't run that spec on Adobe ColdFusion. The framework's own 56 conditional-validation specs, which cover the same grammar, passed on Adobe ColdFusion 2023 and 2025 in the [compatibility matrix run](https://github.com/wheels-dev/wheels/actions/runs/36858895094) on the 4.1.2 release pull request.

## If you're upgrading

1. List your conditions: `git grep -nE '(condition|unless)[[:space:]]*=' -- app config`.
2. Find the ones that won't throw but are read wrong:

   ```bash
   git grep -nE '(condition|unless)[[:space:]]*=[[:space:]]*"([^"]*[[:space:]])?(is|and|or|not)[[:space:]]' -- app
   git grep -nE '(condition|unless)[[:space:]]*=[[:space:]]*"[^"]*(eq|neq|lt|lte|gt|gte|==|!=|<|>)[[:space:]]*this\.' -- app
   ```

3. Add `this.` to every bare property name.
4. Move anything else into a model method and call it with `this.method()`.
5. Test each condition both ways with `valid()`. A grep can't tell you whether a rule runs.

**Previous:** [the `public/Application.cfc` edits between 4.0 and 4.1](https://blog.wheels.dev/blog/from-2x-to-41-application-cfc-4-0-to-4-1). **Next in the series:** replacing your 2.x plugins.

