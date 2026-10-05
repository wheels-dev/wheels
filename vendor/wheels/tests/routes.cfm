<cfscript>
/**
 * Internal GUI Routes
 * TODO: formalise how the cli interacts
 **/
mapper()
    // Browser test fixture routes — mounted during core tests so
    // wheels.tests.specs.wheelstest.Browser* specs can resolve named
    // routes (browserTestHome, browserTestLogin, etc.). Test-asset
    // controllers live in vendor/wheels/tests/_assets/controllers/.
    // Must come before .wildcard().
    .scope(path="/_browser")
        .get(name="browserTestHome", pattern="/home", to="BrowserTestHome##index")
        .get(name="browserTestLogin", pattern="/login", to="BrowserTestSessions##new")
        .post(name="browserTestAuthenticate", pattern="/login", to="BrowserTestSessions##create")
        .get(name="browserTestDashboard", pattern="/dashboard", to="BrowserTestHome##dashboard")
        .post(name="browserTestLogout", pattern="/logout", to="BrowserTestSessions##destroy")
        .get(name="browserTestLoginAs", pattern="/login-as", to="BrowserTestLogin##create")
    .end()
    // Advisory-lock release-on-abort fixtures (#4219) — a lock taken by
    // withAdvisoryLock() whose callback ends the request via abort/redirectTo
    // must still be released (the release runs in a finally). Driven by
    // wheels.tests.specs.model.advisoryLockAbortReleaseSpec. Must precede .wildcard().
    .scope(path="/_advisorylock")
        .get(name="advisoryLockAbortDefault", pattern="/abort-default", to="AdvisoryLockProbe##abortDefault")
        .get(name="advisoryLockRedirectDefault", pattern="/redirect-default", to="AdvisoryLockProbe##redirectDefault")
        .get(name="advisoryLockAbortTx", pattern="/abort-tx", to="AdvisoryLockProbe##abortTransaction")
        .get(name="advisoryLockRedirectTx", pattern="/redirect-tx", to="AdvisoryLockProbe##redirectTransaction")
    .end()
    .wildcard()
	.get(name="wheelstestbox", pattern="wheels/core/tests", to="wheels##public##tests")
	.get(name="sampleLinkToTest", pattern="sample/linktotest", to="sample##linktotest")
	.get(name="sampleLinkToTestTarget", pattern="sample/linktotesttarget", to="sample##linktotesttarget")
.end();

</cfscript>
