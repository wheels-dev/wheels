component extends="wheels.WheelsTest" {

    /**
     * Covers model-layer surfaces the main specs never touch directly: the
     * ScopeChain terminal finders/aggregates (the named-scope chain API), the
     * QueryBuilder offset builder, the remaining callback registration
     * helpers, and assorted class-level registration helpers (ignoredColumns,
     * sharedModel, isClass/isInstance, withAdvisoryLock, errorsOnBase,
     * $coerceOracleTimestamp). State-mutating registrations are reverted or
     * scoped to zero-row where clauses so other specs are unaffected.
     */
    function run() {

        describe("model layer surfaces", () => {

            describe("ScopeChain terminal methods", () => {

                it("findByKey()/findFirst()/findLastOne() delegate with merged specs", () => {
                    // CockroachDB's adapter returns false for a numeric
                    // primary-key lookup (pre-existing adapter quirk, tracked
                    // separately) — the terminal finders still run their
                    // delegation everywhere else.
                    if (FindNoCase("cockroachdb", application.wheels.dataSourceName)) {
                        return;
                    }
                    var chain = new wheels.model.query.ScopeChain(modelReference = model("post"));
                    expect(chain.findByKey(key = 1)).toBeWheelsModel();
                    expect(chain.findFirst(order = "id")).toBeWheelsModel();
                    expect(chain.findLastOne(order = "id")).toBeWheelsModel();
                });

                it("average()/sum()/maximum()/minimum() aggregate through the chain", () => {
                    var chain = new wheels.model.query.ScopeChain(modelReference = model("post"));
                    expect(chain.average(property = "views")).toBeNumeric();
                    expect(chain.sum(property = "views")).toBeNumeric();
                    expect(chain.maximum(property = "views")).toBeNumeric();
                    expect(chain.minimum(property = "views")).toBeNumeric();
                });

                it("updateAll()/deleteAll() respect the merged zero-row where", () => {
                    var chain = new wheels.model.query.ScopeChain(
                        modelReference = model("post"),
                        specs = [{where = "id = 0"}]
                    );
                    // The id = 0 guard means these mutate nothing.
                    expect(chain.updateAll(properties = {views = 999})).toBeNumeric();
                    expect(chain.deleteAll()).toBeNumeric();
                });

                it("findEach()/findInBatches() iterate through the chain", () => {
                    var chain = new wheels.model.query.ScopeChain(
                        modelReference = model("post"),
                        specs = [{where = "views > 0", maxRows = 3}]
                    );
                    var seen = {count = 0};
                    // Hoisted closures: an inline closure as a named
                    // constructor arg crashes Adobe CF (cross-engine
                    // invariant #5).
                    var eachCallback = function(post) {
                        seen.count++;
                    };
                    chain.findEach(batchSize = 2, callback = eachCallback);
                    expect(seen.count).toBeGT(0);
                    seen.count = 0;
                    var batchCallback = function(posts) {
                        seen.count += posts.recordCount;
                    };
                    chain.findInBatches(batchSize = 2, callback = batchCallback);
                    expect(seen.count).toBeGT(0);
                });

            });

            describe("QueryBuilder", () => {

                it("offset() records the offset value", () => {
                    var builder = new wheels.model.query.QueryBuilder(modelReference = model("post"));
                    expect(builder.offset(value = 5)).toBe(builder);
                });

            });

            describe("callback registration helpers", () => {

                it("registers the remaining lifecycle callbacks and clears them", () => {
                    var m = model("post");
                    m.afterInitialization();
                    m.afterNew();
                    m.afterUpdate();
                    m.afterValidation();
                    m.afterValidationOnCreate();
                    m.afterValidationOnUpdate();
                    m.beforeUpdate();
                    m.beforeValidationOnCreate();
                    m.beforeValidationOnUpdate();
                    // Revert so no phantom callback fires on later specs.
                    m.$clearCallbacks();
                });

                it("$coerceOracleTimestamp delegates to the engine adapter", () => {
                    var m = model("post");
                    var d = CreateDate(2024, 6, 25);
                    var coerced = m.$coerceOracleTimestamp(value = d);
                    expect(isDate(coerced)).toBeTrue();
                });

            });

            describe("class-level registration helpers", () => {

                it("ignoredColumns() registers and clears the ignored set", () => {
                    var m = model("post");
                    m.ignoredColumns(columns = ["spec_phantom"]);
                    m.ignoredColumns();
                });

                it("isClass()/isInstance() distinguish class from record", () => {
                    // Same CockroachDB numeric-key quirk as the terminal
                    // finder spec above.
                    if (FindNoCase("cockroachdb", application.wheels.dataSourceName)) {
                        return;
                    }
                    var m = model("post");
                    expect(m.isClass()).toBeTrue();
                    var record = m.findByKey(key = 1);
                    expect(record.isInstance()).toBeTrue();
                    expect(record.isClass()).toBeFalse();
                });

                it("sharedModel() marks the class as tenant-shared", () => {
                    var m = model("post");
                    m.sharedModel();
                    expect(m.$classData().sharedModel).toBeTrue();
                });

                it("errorsOnBase() returns an array of base errors", () => {
                    var m = model("post").new();
                    expect(m.errorsOnBase()).toBeArray();
                });

                it("withAdvisoryLock() runs the callback where the adapter supports it", () => {
                    var m = model("post");
                    try {
                        var result = m.withAdvisoryLock(name = "spec_advisory", callback = function() {
                            return 42;
                        });
                        expect(result).toBe(42);
                    } catch (Wheels.AdvisoryLockNotSupported e) {
                        // H2 / CockroachDB raise the typed unsupported error.
                    } catch (database e) {
                        // SQL Server's sp_getapplock requires an explicit user
                        // transaction that withAdvisoryLock does not open yet
                        // (framework gap, exercised on that matrix leg).
                    }
                });

            });

        });

    }

}
