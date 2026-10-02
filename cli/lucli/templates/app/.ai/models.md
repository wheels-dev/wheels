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
Opt a `select=false` calculated property into one call (additive): `findAll(includeCalculated="fullName")`. Unknown names throw `Wheels.CalculatedPropertyNotFound` in dev/testing.

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
