---
name: Wheels Migration Generator
description: Generate database-agnostic Wheels migrations for creating tables, altering schemas, and managing database changes. Use when creating or modifying database schema, adding tables, columns, indexes, or foreign keys. Prevents database-specific SQL and ensures cross-database compatibility.
---

# Wheels Migration Generator

## When to Use This Skill

- Creating or dropping tables
- Adding, changing, renaming, or removing columns, indexes, and foreign keys
- Seeding reference data

## Conventions

- Migrations live in `app/migrator/migrations/`, are named `<timestamp>_<Description>.cfc`, and extend `"wheels.migrator.Migration"`. Generate the file with `wheels g migration CreatePostsTable` so the timestamp is correct.
- Every `up()` has a `down()` that reverses it. Wrap each in `transaction { }`.
- Column helpers take `columnNames` (a list), and nullability is `allowNull` (not `null`).
- `t.timestamps()` adds three columns: `createdAt`, `updatedAt`, and `deletedAt` (the soft-delete marker). Don't add them separately.
- Keep SQL database-agnostic. `execute()` takes one SQL string with no parameter binding, so inline the values, and use `CURRENT_TIMESTAMP` rather than `NOW()`, which fails on SQLite and SQL Server.

The files in `app/migrator/migrations/` are working examples in this app.

## Create a Table

```cfm
component extends="wheels.migrator.Migration" hint="CreatePostsTable" {

	function up() {
		transaction {
			t = createTable(name="posts");
			t.references(columnNames="user");                  // userId column + foreign key
			t.string(columnNames="title", limit=200, allowNull=false);
			t.string(columnNames="slug", limit=200, allowNull=false);
			t.text(columnNames="body");
			t.boolean(columnNames="published", default=false, allowNull=false);
			t.decimal(columnNames="price", precision=10, scale=2);
			t.datetime(columnNames="publishedAt");
			t.timestamps();
			t.create();

			addIndex(table="posts", columnNames="userId,slug", unique=true);
		}
	}

	function down() {
		transaction {
			dropTable("posts");
		}
	}

}
```

Other column helpers: `integer`, `bigInteger`, `float`, `char`, `date`, `time`, `timestamp`, `binary`, `uniqueidentifier`. For a composite index, put the column you filter on most first.

## Alter a Table

```cfm
function up() {
	transaction {
		addColumn(table="posts", columnType="integer", columnName="viewsCount", default=0, allowNull=false);
		renameColumn(table="posts", columnName="body", newColumnName="content");
		addIndex(table="posts", columnNames="publishedAt", indexName="idx_posts_publishedAt");
	}
}

function down() {
	transaction {
		removeIndex(table="posts", indexName="idx_posts_publishedAt");
		renameColumn(table="posts", columnName="content", newColumnName="body");
		removeColumn(table="posts", columnName="viewsCount");
	}
}
```

For several changes to one table, `t = changeTable(name="posts")` followed by the same column helpers and `t.change()` also works. Name indexes explicitly when `down()` needs to remove them.

## Foreign Keys

`t.references(columnNames="user")` creates `userId` and its foreign key in one step. (With `useUnderscoreReferenceColumns=true` it creates `user_id` instead.) For an existing column, or for a self-referential table where the column name can't follow the convention, add it explicitly:

```cfm
addForeignKey(table="follows", referenceTable="users", column="followerId", referenceColumn="id");
addForeignKey(table="follows", referenceTable="users", column="followingId", referenceColumn="id");
```

## Seed Data

```cfm
execute("INSERT INTO roles (name, createdAt, updatedAt) VALUES ('admin', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)");
```

For anything beyond a few reference rows, use `wheels seed` instead of a migration.

## Running Migrations

```bash
wheels migrate latest    # apply pending
wheels migrate down      # roll back the last one
wheels migrate info      # show status
wheels migrate doctor    # report mismatches after a failed run
```

When a migration fails partway, fix it and run `wheels migrate down` then `wheels migrate latest`, or use `doctor` to see what was left behind. In production, only run `latest`. Before finishing, check that the migration round-trips: `wheels migrate latest && wheels migrate down && wheels migrate latest`.

## Related Skills

- **wheels-model-generator**: Creates models for tables
- **wheels-anti-pattern-detector**: Validates migration code

Framework reference: https://guides.wheels.dev
