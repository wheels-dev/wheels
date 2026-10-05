# Model Quick Reference

Part of the Wheels application guide; start with `../CLAUDE.md`.

```cfm
component extends="Model" {
    function config() {
        // Table/key (only if non-conventional)
        table("tbl_users");        // setter is table(); tableName() is a getter — tableName("x") throws Wheels.InvalidArgument in dev/testing, no-op in production (#3079)
        setPrimaryKey("userId");

        // Associations — all named params when using options
        hasMany(name="orders", dependent="delete");
        belongsTo(name="role");

        // Validations
        validatesPresenceOf("firstName,lastName,email");
        validatesUniquenessOf(property="email");
        validatesFormatOf(property="email", regEx="^[\w\.-]+@[\w\.-]+\.\w+$");

        // Callbacks
        beforeSave("sanitizeInput");
        // afterCommit/afterRollback run AFTER the transaction resolves — use these
        // for side effects that must not happen on a rollback (jobs, mail, caches,
        // external calls). Optional on="create,update,delete" filter; nested writes
        // and invokeWithTransaction() blocks fire once together on the outermost
        // commit; with transactionMode="none" afterCommit fires immediately per op.
        // IMPORTANT: afterCommit/afterRollback are only reliable inside a Wheels-managed
        // transaction — transaction() / invokeWithTransaction(). A write placed inside a
        // raw CFML `transaction {}` block is SKIPPED (with a one-time wheels.log warning)
        // on Lucee and BoxLang, and is NOT detectable on Adobe CF or RustCFML — there the
        // behaviour inside a raw transaction{} is left to the engine and is not guaranteed.
        // Always use the Wheels-managed transaction for these callbacks.
        // Nested units: save(transaction="savepoint") / invokeWithTransaction(..., transaction="savepoint")
        // run as a savepoint inside an already-open transaction — on a false return or a throw only that
        // unit's own writes roll back and the outer transaction carries on; with no open transaction it
        // behaves like transaction="commit".
        afterCommit("enqueueSearchIndex", on="create,update");
        afterRollback("releaseReservation");

        // Calculated SQL properties — select=false keeps them off the default SELECT (hot path)
        property(name="fullName", sql="firstName || ' ' || lastName", select=false);

        // Query scopes — reusable, composable query fragments
        scope(name="active", where="status = 'active'");
        scope(name="recent", order="createdAt DESC");
        scope(name="byRole", handler="scopeByRole");  // dynamic scope

        // Enums — named values with auto-generated checkers and scopes
        enum(property="status", values="draft,published,archived");
        enum(property="priority", values={low: 0, medium: 1, high: 2});
    }

    private struct function scopeByRole(required string role) {
        return {where: "role = '#arguments.role#'"};
    }
}
```

Finders: `model("User").findAll()`, `findOne(where="...")`, `findByKey(params.key)`.
Create: `model("User").new(params.user).save()`, or `model("User").create(params.user)`.
Include associations: `findAll(include="role,orders")`. Pagination: `findAll(page=params.page, perPage=25)`.
What the last save wrote (4.2+): `savedChanges()`, `hasSavedChange("status")`, `savedChangeFrom("status")`, `savedChangedProperties()`, the saved counterparts of `allChanges()` / `hasChanged()` / `changedFrom()` / `changedProperties()`. Use them in `afterCommit`: each call sees the save that queued it, so a record saved twice in one transaction is told apart, and no hand-kept flag is needed (`if (hasSavedChange("published") && this.published) ...`).
Opt a `select=false` calculated property into one call (additive): `findAll(includeCalculated="fullName")`. Unknown names throw `Wheels.CalculatedPropertyNotFound` in dev/testing.

Literal LIKE search: `findAll(where="title LIKE '%#escapeForLike(params.q)#%' ESCAPE '\'")`. `escapeForLike()` escapes `\` `%` `_` (and `[` on SQL Server — `\[` is illegal on Oracle; on SQL Server `[` is escaped only after a model has initialised the adapter, so call a `model()` finder before using it in a fresh/just-reloaded app) so a user's term isn't read as wildcards; the quoted literal is bound. Always declare `ESCAPE '\'`: MySQL/PG/CockroachDB/H2 default the escape char to `\` but SQLite/Oracle/SQL Server have none, and the 3-arg builder `where("title","LIKE",...)` emits no `ESCAPE`, so without it `\` matches literally. Escapes LIKE metacharacters only, not SQL quotes.

## Scopes / Enums / Builder / Batch

```cfm
// Scopes — chain composably
model("User").active().recent().findAll();
model("User").byRole("admin").findAll(page=1, perPage=25);

// Enums — auto-generated checkers and scopes
user.isDraft();                    // true/false
model("User").draft().findAll();

// Chainable query builder (2-/3-arg where is injection-safe; 1-arg is raw SQL)
model("User")
    .where("status", "active")
    .where("age", ">", 18)
    .whereNotNull("emailVerifiedAt")
    .orderBy("name", "ASC")
    .limit(25)
    .get();
// Methods: where, orWhere, whereNull, whereNotNull, whereBetween, whereIn, whereNotIn, orderBy,
// limit, offset, select, include, group, distinct, forUpdate, get
// Any of these (not just where) can START the chain on the model, e.g. model("User").select("id,name").get()

// Batch processing — memory-efficient
model("User").findEach(batchSize=1000, callback=function(user) {
    user.sendReminderEmail();
});
model("User").findInBatches(batchSize=500, callback=function(users) {
    processUserBatch(users);
});
```

## Soft delete (on by default when the table has `deletedAt`)

A model whose table has a `deletedAt` column soft-deletes. `t.timestamps()` adds `deletedAt` along with `createdAt` and `updatedAt`, so most tables do. The column name comes from the `softDeleteProperty` setting; set it to `""` to turn soft delete off app-wide.

- `delete()`, `deleteAll()`, `deleteOne()` and `deleteByKey()` run `UPDATE ... SET deletedAt = <timestamp>` instead of `DELETE`. The timestamp follows `timeStampMode` (UTC by default). `beforeDelete` / `afterDelete` still run.
- Finders skip soft-deleted rows: `findAll`, `findOne`, `findByKey`, `findEach`, `findInBatches`, paginated `findAll(page=)`, `count` / `sum` / `average` / `minimum` / `maximum`, `exists`, association readers (`post.comments()`), `updateAll` / `updateOne` / `updateByKey`, and the query builder. Soft-deleted rows on an `include=` join are filtered too.
- Pass `includeSoftDeletes=true` to see them: `model("Post").findAll(where="authorId = 7", includeSoftDeletes=true)`.
- Remove a row for good with `softDelete=false`. For rows that are already soft-deleted, pass both: `model("Post").deleteAll(where="...", softDelete=false, includeSoftDeletes=true)`.
- Restore: `model("Post").updateByKey(key=params.key, deletedAt="", includeSoftDeletes=true)`.
- `validatesUniquenessOf` ignores soft-deleted rows, but a database unique index does not: a new row can pass validation and still hit the index.

Gotcha in specs: after `post.delete()`, `model("Post").findByKey(post.id)` returns `false` and `count()` drops, but the row is still in the table. To assert a permanent delete, look with `includeSoftDeletes=true` or delete with `softDelete=false`.

## `dependent=` on `hasMany` / `hasOne`

```cfm
hasMany(name="comments", dependent="delete");
```

| Value | What happens to the children when the parent is deleted |
|---|---|
| `delete` | Each child is loaded and `delete()`d: its callbacks and its own `dependent=` run. |
| `deleteAll` | One `DELETE` (or soft-delete `UPDATE`) statement: no child callbacks. |
| `remove` | Each child is loaded and its foreign key set to NULL through `update()` (validations and callbacks run; a child that fails validation keeps its key). |
| `removeAll` | One `UPDATE ... SET <foreignKey> = NULL` statement. |
| `false` (default) | Nothing. |

On `hasOne`, `delete` and `deleteAll` both load the child and call `delete()`; `remove` and `removeAll` both go through `update()`.

Order inside the parent's `delete()` transaction: the parent's `beforeDelete`, then the dependents, then the parent row, then `afterDelete`. If `beforeDelete` returns `false` nothing is deleted; if the parent delete fails, the children's changes roll back with it. `deleteAll()` on the parent without `instantiate=true` runs no callbacks and no `dependent=`.

## Bulk writes: `insertAll` / `upsertAll`

```cfm
result = model("Product").insertAll(records=[{sku="A1", name="Bolt"}, {sku="A2", name="Nut"}]);   // {insertedCount: 2}
result = model("Product").upsertAll(records=rows, uniqueBy="sku");                                 // {upsertedCount: n}
```

- No validations and no callbacks of any kind (including `afterCommit`): they write SQL directly. `createdAt` / `updatedAt` are filled in when missing.
- Every record must have the same keys, or `Wheels.InvalidRecordKeys` is thrown. Keys that aren't model properties are dropped.
- `insertAll` has no "ignore duplicates" option: a unique violation throws. Use `upsertAll` when rows may already exist.
- The count is the number of records you passed, not the number the database changed, and no generated keys come back. Read the rows back if you need their ids.
- Rows are written in batches of 1000.

## `afterCommit` / `afterRollback` details

- The callback runs on the same in-memory object that was saved, not a fresh copy from the database. `savedChanges()` inside it shows that save's changes.
- It is queued once per successful `save()` / `delete()`, with no de-duplication: saving one record twice in a transaction (or through two objects) runs it twice, in save order. A `save()` that changed nothing still counts as a successful update and queues it.
- Outside an explicit transaction, each `save()` is its own transaction, so `afterCommit` runs before `save()` returns.
- A save that fails validation, or that a `before*` callback stops, queues nothing, so it gets no `afterRollback` either.

## `order=`

- Property names are quoted for you, so a property named after a reserved word (`order="rank DESC"`) is safe. `ASC` / `DESC` may be any case.
- `order="comments.createdAt"` (table.column) orders by a column of an included association.
- Raw expressions (anything with parentheses) throw `Wheels.InvalidOrderClause`: define a calculated property and order by its name instead.
  ```cfm
  property(name="lastActivity", sql="COALESCE(updatedAt, createdAt)");
  model("Post").findAll(order="lastActivity DESC");
  ```
- `order="random"` uses the database's random order.

`updateAll` binds every value as a parameter, so `updateAll(position="position - 1")` is never evaluated as SQL. There is no increment/decrement API: for a value relative to its current one, use a parameterized `queryExecute("UPDATE ... SET position = position - 1 WHERE ...", {...})` (inside `transaction()` if it goes with other writes).
