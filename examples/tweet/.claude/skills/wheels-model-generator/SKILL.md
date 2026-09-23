---
name: Wheels Model Generator
description: Generate Wheels ORM models with proper validations, associations, and methods. Use when the user wants to create or modify a Wheels model, add validations, define associations (hasMany, belongsTo, hasManyThrough), or implement custom model methods. Prevents common Wheels-specific errors like mixed argument styles and ensures proper CFML syntax.
---

# Wheels Model Generator

## When to Use This Skill

- Creating a model or changing its associations, validations, or callbacks
- Adding custom model methods (scopes, computed values, domain logic)

## Conventions

- Models are singular PascalCase (`Post.cfc`), extend `"Model"`, and map to a plural lowercase table (`posts`). Call `table("...")` only when the table name breaks the convention.
- Associations, validations, and callbacks go in `config()`.
- **Don't mix argument styles within one call.** A call with options names every argument: `hasMany(name="comments", dependent="delete")`, not `hasMany("comments", dependent="delete")`. A bare `hasMany("comments")` is fine.
- **Validation arguments:** `property` for one property and `properties` for a list; every `validates*Of()` helper accepts both. Custom validators use `validate(methods="checkSomething")`.
- **Primary keys:** Wheels reads the primary key from the table schema, so a conventional `id` column needs no declaration. Call `setPrimaryKey("<column>")` only when the database doesn't flag the column as the primary key (legacy tables, views), and `setPrimaryKeys("a,b")` for composite keys.
- **Callbacks see only the properties that were set.** A property that wasn't passed to `new()` or `create()` doesn't exist on the object yet, so check with `StructKeyExists(this, "x")` before reading it in `beforeValidation` / `beforeCreate`.
- Finders return queries (`findAll`, association methods like `post.comments()`) or objects (`findByKey`, `findOne`). Use `.recordCount` on queries, not `ArrayLen()`.

`app/models/User.cfc` and `Tweet.cfc` in this app are working examples.

## Template

```cfm
component extends="Model" {

	function config() {
		// Associations
		belongsTo(name="user");
		hasMany(name="comments", dependent="delete");
		hasMany(name="taggings", shortcut="tags");  // adds post.tags() via Tagging.cfc

		// Validations
		validatesPresenceOf(properties="title,body,userId");
		validatesLengthOf(property="title", maximum=200);
		validatesUniquenessOf(property="slug", scope="userId");
		validatesInclusionOf(property="status", list="draft,published");
		validate(methods="publishDateNotInPast");

		// Callbacks
		beforeValidation("setDefaults");
	}

	function setDefaults() {
		if (!StructKeyExists(this, "status") || !Len(this.status)) {
			this.status = "draft";
		}
	}

	function publishDateNotInPast() {
		if (StructKeyExists(this, "publishedAt") && IsDate(this.publishedAt) && this.publishedAt < Now()) {
			addError(property="publishedAt", message="Publish date can't be in the past.");
		}
	}

	public query function published() {
		return findAll(where="status = 'published'", order="publishedAt DESC");
	}

}
```

## Associations

| Relationship | Declaration |
|---|---|
| Child belongs to parent | `belongsTo(name="user")`, which uses the `userId` foreign key |
| Parent has many children | `hasMany(name="comments")` |
| One-to-one | `hasOne(name="profile")` |
| Many-to-many through a join model | `hasMany(name="taggings", shortcut="tags")` on Post (and `shortcut="posts"` on Tag), with `Tagging.cfc` declaring `belongsTo()` for both; `shortcut=` adds the `tags()` method |
| Self-referential or non-conventional | add `modelName=` and `foreignKey=`, as `User.cfc` does for followers and following |

Cascade deletes with `dependent="delete"` (loads each child, so its callbacks run) or `dependent="deleteAll"` (one query, no callbacks). `remove` / `removeAll` null the foreign key instead.

## Soft Delete and Timestamps

Migrations that call `t.timestamps()` add `createdAt`, `updatedAt`, and `deletedAt`. Wheels sets the first two automatically, and a table with `deletedAt` is soft-deleted: `delete()` stamps the column and finders skip those rows unless you pass `includeSoftDeletes=true`.

## Before You Finish

- Every call that passes options uses named arguments.
- Callbacks guard properties that may not be set yet.
- The table and columns exist; run `wheels migrate latest` if you also wrote a migration.
- Write a spec (see **wheels-test-generator**) for each validation and custom method.

## Related Skills

- **wheels-anti-pattern-detector**: Validates generated model code
- **wheels-migration-generator**: Creates database schema for model
- **wheels-test-generator**: Creates WheelsTest specs for model
- **wheels-controller-generator**: Creates controller for model

Framework reference: https://guides.wheels.dev
