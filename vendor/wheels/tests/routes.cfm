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
    .wildcard()
	.get(name="wheelstestbox", pattern="wheels/core/tests", to="wheels##public##tests")
	.get(name="sampleLinkToTest", pattern="sample/linktotest", to="sample##linktotest")
	.get(name="sampleLinkToTestTarget", pattern="sample/linktotesttarget", to="sample##linktotesttarget")
.end();

</cfscript>
