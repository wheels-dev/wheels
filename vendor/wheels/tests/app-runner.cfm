<cfsetting requestTimeOut="1800">
<cfscript>
    // The run's own request timeout, re-applied after tests/populate.cfm (below),
    // which an app may have written to lower it.
    local.runnerRequestTimeout = Max(1800, application.wo.$getRequestTimeout());
    // Built-in app-test runner. Used as a fallback by Public.cfc::testbox()
    // when the project doesn't have its own tests/runner.cfm. Scans the
    // project's tests/specs/ via TestBox and emits the same JSON shape as
    // the framework's core runner so the CLI's displayTestResults() can
    // parse it without a special case.
    //
    // The framework's runner (vendor/wheels/tests/runner.cfm) is heavy: it
    // overrides controllerPath/viewPath/modelPath to framework test assets,
    // hardcodes the wheelstestdb_<db> datasource convention, and applies
    // dozens of test-only settings. None of that fits user apps — user
    // tests should run against the same models/controllers/views that
    // power the live application, with the user's own datasource. So this
    // file deliberately does NOT include /wheels/tests/runner.cfm.

    // Resolve the test directory. Default to tests.specs (the convention
    // every Wheels app has), but allow ?directory= to scope to a subdir
    // like tests.specs.models. The resolver only accepts dotted paths
    // beginning with "tests." so a malicious caller can't trick TestBox
    // into compiling arbitrary CFCs (e.g. ?directory=vendor.wheels.lib).
    // Extracted to TestDirectoryResolver so the regression spec for
    // issue #2489 can exercise the regex without spinning up HTTP.
    //
    // resolveScope() additionally records whether a present-but-rejected
    // directory was silently swapped for the default, so a green total from
    // the wrong scope is detectable in the JSON payload (issue #3083).
    // Hard-refuse the app test runner in production,
    // independent of enablePublicComponent. Running specs in production can hit
    // the real database and re-run app start-up side effects. The onApplicationStart
    // backstop already refuses an isolated start outside dev/testing; this is the
    // belt-and-suspenders at the runner itself. Minimal 403, no detail.
    if (
        StructKeyExists(application, "wheels")
        && StructKeyExists(application.wheels, "environment")
        && application.wheels.environment == "production"
    ) {
        cfheader(statuscode = 403);
        cfheader(name = "Content-Type", value = "text/plain; charset=utf-8");
        writeOutput("Forbidden");
        abort;
    }

    // Warn when test-context isolation is OFF (the request bound the
    // live application scope instead of <name>_wheelsTest) — specs then mutate
    // live application settings. Set WHEELS_ENV=development or testing so
    // events/testcontext.cfm binds the isolated application.
    if (!(Len(application.applicationName) >= 11 && Right(application.applicationName, 11) == "_wheelsTest")) {
        cfheader(name = "X-Wheels-Test-Isolation", value = "off");
        try {
            writeLog(
                file = "wheels",
                type = "warning",
                text = "Test runner isolation is OFF: application '" & application.applicationName & "' is not the isolated _wheelsTest scope, so specs run against (and mutate) the live application. Set WHEELS_ENV=development or testing."
            );
        } catch (any e) {}
    }

    // Which datasource the run uses is decided inside the runner lock below by
    // $testDataSourceDecision() (global/util.cfm), the one rule every app test
    // runner shares: <datasource>_test when it is registered; the primary
    // datasource only for an explicit useTestDB=false, or for an omitted useTestDB
    // with allowTestsAgainstPrimaryDatasource=true; otherwise the run is refused.

    local.dirResolver = new wheels.tests._assets.dispatch.TestDirectoryResolver();
    local.testScope = local.dirResolver.resolveScope(url);
    local.testDirectory = local.testScope.resolved;

    // Drop the compiled pages held in memory so this run compiles what is on
    // disk now. Lucee's default inspectTemplate ("auto") re-checks templates
    // only on a background sweep, so a run started just after a spec was
    // edited could still run the previous version (#3962). Coverage relies on
    // this too: `wheels coverage` instruments app/ just before this request,
    // and under inspectTemplate=once a server that had served the app kept
    // running the uninstrumented code and reported 0% (deleting cfclasses on
    // disk does not drop the pages held in memory). Lucee-only function, hence
    // the guard.
    if (StructKeyExists(GetFunctionList(), "pagePoolClear")) {
        pagePoolClear();
    }

    // Coverage mode (`wheels coverage`): reset the function-level counter map
    // so the dump at the end of this request reflects only THIS run.
    if (StructKeyExists(url, "coverage") && url.coverage) {
        server.__wheels_cov = {};
        // Wheels runs each controller's and model's config() once and caches the
        // class, so on a warm server config() never ran during the suite and its
        // counters stayed at zero. Drop the class caches so they are rebuilt from
        // the instrumented code; the app rebuilds them lazily on the next use.
        for (local.classCache in ["controllers", "models"]) {
            if (StructKeyExists(application.wheels, local.classCache) && IsStruct(application.wheels[local.classCache])) {
                StructClear(application.wheels[local.classCache]);
            }
        }
    }

    // Resolve the target datasource. When url.useTestDB=true and a
    // <dataSourceName>_test datasource is registered, swap to it for
    // the duration of this run. Mirrors Rails' RAILS_ENV=test convention
    // without requiring users to manage two databases by hand. The CLI
    // passes useTestDB=true by default for `wheels test`; users opt out
    // via --no-test-db. See finding #10 in
    // docs/superpowers/plans/2026-04-29-fresh-vm-onboarding-findings.md.
    // The swap goes through applyDataSource() so cached model classes re-initialize against the test datasource.
    local.dbResolver = new wheels.tests._assets.dispatch.TestDbResolver();

    // The swap->run->restore window mutates application.wheels.dataSourceName,
    // a value shared by every concurrent request on the app instance. Two
    // overlapping test runs used to race the capture/restore — one could
    // capture the already-swapped value as its "original" and strand the app
    // on the test datasource (issue #3427). Serialize the whole window under
    // an exclusive named lock (precedent: vendor/wheels/tests/runner.cfm
    // #3373, and migrator/TenantMigrator.cfc::$runForTenant).
    //
    // Re-entrancy: a spec that re-enters /wheels/app/tests while the parent
    // request holds the swap + lock would deadlock on the shared lock. The
    // runner-owns-swap flag plus a unique per-request suffix turn a re-entrant
    // request's lock into a no-op, matching the core runner.
    //
    // A re-entrant request must also echo the in-progress run's token
    // (url.wheelsTestRun = application.$$$appTestRunToken). The marker alone
    // is not enough: a run the CLI abandoned on timeout keeps executing, and an
    // immediate re-run used to see its marker, skip the lock and run
    // concurrently against the same test database (issue #3683). Without the
    // token an overlapping run now queues on the lock instead.
    local.activeRunToken = StructKeyExists(application, "$$$appTestRunToken") ? application["$$$appTestRunToken"] : "";
    local.requestRunToken = (StructKeyExists(url, "wheelsTestRun") && IsSimpleValue(url.wheelsTestRun)) ? url.wheelsTestRun : "";
    // A project tests/runner.cfm that includes this file runs inside
    // Public.cfc's $runProjectTestRunner(), which already holds this lock and has
    // already chosen (and, on a swap, applied) the test datasource. Neither the
    // lock nor the swap is repeated here, and the outer runner restores.
    local.outerRunner = StructKeyExists(request, "wheels")
        && StructKeyExists(request.wheels, "$testRunnerOuter")
        && request.wheels.$testRunnerOuter;
    local.preSwap = (local.outerRunner && StructKeyExists(request.wheels, "$testRunPreSwap")) ? request.wheels.$testRunPreSwap : {};
    local.runnerOwnsSwap = !local.outerRunner && !(
        StructKeyExists(application, "$$$appTestOriginalDataSource")
        && Len(local.activeRunToken)
        && Compare(local.requestRunToken, local.activeRunToken) == 0
    );
    local.runnerLockSuffix = local.runnerOwnsSwap ? "" : "_sub_" & CreateUUID();
    // Timeout must exceed the worst-case full-suite duration; matches the
    // requestTimeout at the top of this template.
    lock name="wheelsTestRunner_#application.applicationName##local.runnerLockSuffix#" type="exclusive" timeout="1800" throwontimeout="true" {
        try {
            // Holding the exclusive lock means no other owner is live, so swap
            // markers still present were stranded by a run that died before its
            // finally block: restore the settings they recorded before reading them.
            if (local.runnerOwnsSwap) {
                application.wo.$recoverStrandedTestRun(force = true);
            }
            local.originalDataSource = application.wheels.dataSourceName;
            local.targetDataSource = local.originalDataSource;
            // Pre-swapped by the outer runner: populate the test datasource as a swap would.
            local.swappedDataSource = !StructIsEmpty(local.preSwap);
            if (local.runnerOwnsSwap) {
                local.decision = application.wo.$testDataSourceDecision(primary = local.originalDataSource, requestUrl = url);
                if (local.decision.action == "refuse") {
                    // Never silently run specs (which may write) against the primary
                    // datasource. Nothing has been changed yet, so nothing to restore.
                    cfheader(statuscode = 409);
                    cfcontent(type = "application/json");
                    writeOutput(SerializeJSON(application.wo.$testDataSourceRefusal(decision = local.decision)));
                    abort;
                }
                // The run token and the swap markers let re-entrant sub-requests skip the
                // swap and the shared lock, and let a later request restore the settings
                // if this run dies before its finally block.
                application["$$$appTestRunToken"] = CreateUUID();
                application.wo.$markTestRunSwap(original = local.originalDataSource);
                if (local.decision.action == "swap") {
                    local.targetDataSource = local.decision.target;
                    local.dbResolver.applyDataSource(
                        wheelsScope = application.wheels,
                        name = local.decision.target
                    );
                    local.swappedDataSource = true;
                    application.wo.$warnLiveScopeTestSwap(primary = local.originalDataSource, target = local.decision.target);
                } else if (local.decision.warn) {
                    application.wo.$warnTestsOnPrimaryDataSource(decision = local.decision);
                }
            }

            // Always include the user's tests/populate.cfm before specs run so
            // pending migrations reach the test DB on every run
            // (migrateToLatest() is a no-op when already current) — gating on
            // "no migrator-versions table" meant migrations added after the
            // first run never reached db/test.sqlite and their specs failed
            // with "table could not be found". Seed data added to
            // populate.cfm must be idempotent: it runs before every test run.
            // Skip silently when the file doesn't exist (advanced users with
            // their own setup).
            local.populatePath = ExpandPath("/tests/populate.cfm");
            if (local.swappedDataSource && FileExists(local.populatePath)) {
                try {
                    include "/tests/populate.cfm";
                } catch (any populateErr) {
                    // Surface populate.cfm errors as JSON; don't silently
                    // run specs against an empty test DB.
                    cfheader(statuscode = 500);
                    cfcontent(type = "application/json");
                    writeOutput(SerializeJSON({
                        success: false,
                        error: "tests/populate.cfm failed",
                        message: populateErr.message,
                        detail: populateErr.detail
                    }));
                    abort;
                }
            }
            // tests/populate.cfm may lower the request timeout (the `wheels new`
            // template set 300 seconds until 4.2), which then cut long runs short.
            // The specs run under the runner's own limit.
            if (application.wo.$getRequestTimeout() < local.runnerRequestTimeout) {
                setting requestTimeout = local.runnerRequestTimeout;
            }

            // Expand the TestBox mapping up front so constructor / run failures
            // can report the filesystem path (a missing `/tests` mapping after
            // applicationStop() looks exactly like "specs failed to compile").
            local.testFsPath = ExpandPath("/" & Replace(local.testDirectory, ".", "/", "all"));
            local.testDirectoryExists = DirectoryExists(local.testFsPath);

            try {
                // A single spec file runs as its one bundle (issue 3759).
                local.testBoxArgs = local.dirResolver.testBoxArgs(scope = local.testScope);
                testBox = new wheels.wheelstest.system.TestBox(argumentCollection = local.testBoxArgs);
            } catch (any e) {
                cfheader(statuscode="500");
                cfcontent(type="application/json");
                writeOutput(SerializeJSON({
                    success: false,
                    error: "Failed to create TestBox instance",
                    message: e.message,
                    detail: e.detail ?: "",
                    directoryResolved: local.testDirectory,
                    testDirectoryPath: local.testFsPath,
                    testDirectoryExists: local.testDirectoryExists
                }));
                abort;
            }

            // Sort bundles for stable output
            local.sortedBundles = testBox.getBundles();
            arraySort(local.sortedBundles, "textNoCase");
            testBox.setBundles(local.sortedBundles);

            // Surface a rejected directory or a 0-bundle discovery so neither
            // silently reports green for the wrong scope (issue #3083).
            local.bundlesDiscovered = ArrayLen(local.sortedBundles);
            local.scopeWarnings = local.dirResolver.scopeWarnings(
                scope = local.testScope,
                bundlesDiscovered = local.bundlesDiscovered
            );
            if (!local.testDirectoryExists) {
                ArrayAppend(
                    local.scopeWarnings,
                    "Test directory mapping '" & local.testDirectory & "' expanded to '"
                    & local.testFsPath & "' which does not exist."
                );
            }

            // Resolve the output format (reporter + content type + whether to
            // render an HTML report) through TestFormatResolver so the rule is
            // unit-testable without an HTTP request (see AppRunnerTestFormatSpec,
            // issue #3251). An unrecognized format resolves to recognized=false:
            // the runner emits nothing, preserving the historical behavior.
            local.fmtResolver = new wheels.tests._assets.dispatch.TestFormatResolver();
            local.output = local.fmtResolver.resolveFormat(url);

            // Same as the core runner (vendor/wheels/tests/runner.cfm): delay
            // redirectTo() so processRequest() can read getRedirect() instead
            // of the action cflocation-aborting this HTTP request. Without
            // this, a scaffold create/update/delete spec 303s the runner to
            // /posts/:key; show.cfm then does post.title on findByKey()=false
            // ("there is no property with name [TITLE] found in [boolean]").
            local.originalRedirectDelay = false;
            if (
                StructKeyExists(application.wheels, "functions")
                && StructKeyExists(application.wheels.functions, "redirectTo")
                && StructKeyExists(application.wheels.functions.redirectTo, "delay")
            ) {
                local.originalRedirectDelay = application.wheels.functions.redirectTo.delay;
            }
            if (
                StructKeyExists(application.wheels, "functions")
                && StructKeyExists(application.wheels.functions, "redirectTo")
            ) {
                application.wheels.functions.redirectTo.delay = true;
            }

            if (local.output.recognized) {
                try {
                    result = testBox.run(reporter = local.output.reporter);
                } catch (any runErr) {
                    cfheader(statuscode = 500);
                    cfcontent(type = "application/json");
                    writeOutput(SerializeJSON({
                        success: false,
                        error: "TestBox run failed",
                        message: application.wo.$testRunFailureMessage(runErr = runErr),
                        detail: runErr.detail ?: "",
                        // A run that did not finish reports an error, never an empty pass.
                        totalPass: 0,
                        totalFail: 0,
                        totalError: 1,
                        bundlesDiscovered: local.bundlesDiscovered,
                        directoryResolved: local.testDirectory,
                        testDirectoryPath: local.testFsPath,
                        testDirectoryExists: local.testDirectoryExists,
                        warnings: local.scopeWarnings
                    }));
                    abort;
                }

                if (local.output.rendersHtml) {
                    // Render the TestBox-style HTML report for the html / no-format
                    // default, mirroring the core runner (vendor/wheels/tests/runner.cfm).
                    // html.cfm has a type="App" branch (package=tests.specs,
                    // route=testbox) built for exactly this. Previously this branch
                    // emitted raw JSON, so a user opening /wheels/app/tests?format=html
                    // in a browser got JSON instead of the report (issue #3251 item 1).
                    decoded = DeserializeJSON(result);
                    cfheader(statuscode = (decoded.totalFail > 0 || decoded.totalError > 0) ? 417 : 200);
                    type = "App";
                    include "html.cfm";
                } else if (local.output.format == "json") {
                    decoded = DeserializeJSON(result);
                    if (decoded.totalFail > 0 || decoded.totalError > 0) {
                        if (!StructKeyExists(url, "cli") || !url.cli) {
                            cfheader(statuscode = 417);
                        }
                    } else {
                        cfheader(statuscode = 200);
                    }
                    cfcontent(type = local.output.contentType);
                    cfheader(name="Access-Control-Allow-Origin", value="*");
                    writeOutput(local.dirResolver.injectScopeMetadata(
                        resultJson = result,
                        scope = local.testScope,
                        bundlesDiscovered = local.bundlesDiscovered,
                        warnings = local.scopeWarnings
                    ));
                } else {
                    // txt / junit: emit the reporter output verbatim under the
                    // resolved content type.
                    cfcontent(type = local.output.contentType);
                    writeOutput(result);
                }
            }
            // Unrecognized format (empty value / unknown token): no output, and
            // testBox is not run — html.cfm must not be rendered for an arbitrary
            // url.format (it 500s on Adobe). Mirrors the pre-fix fall-through.
        } finally {
            // Restore the original datasource (via applyDataSource() so test-run
            // cached model classes are invalidated). Only the request that
            // performed the swap restores it — re-entrant sub-requests never
            // touch the live config.
            if (
                StructKeyExists(application, "wheels")
                && StructKeyExists(application.wheels, "functions")
                && StructKeyExists(application.wheels.functions, "redirectTo")
                && StructKeyExists(local, "originalRedirectDelay")
            ) {
                application.wheels.functions.redirectTo.delay = local.originalRedirectDelay;
            }
            if (local.runnerOwnsSwap) {
                if (local.swappedDataSource) {
                    local.dbResolver.applyDataSource(
                        wheelsScope = application.wheels,
                        name = local.originalDataSource
                    );
                }
                application.wo.$clearTestRunSwapMarkers();
            }
            // Coverage mode (`wheels coverage`): dump the function-level counter
            // map to an absolute path the CLI reads. Failure must never break the
            // test response, so this is best-effort.
            if (StructKeyExists(url, "coverage") && url.coverage) {
                try {
                    FileWrite("/tmp/wheels-app-coverage.json", SerializeJSON(server.__wheels_cov));
                } catch (any e) {
                }
            }
        }
    }
</cfscript>
