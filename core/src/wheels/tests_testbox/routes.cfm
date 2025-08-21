<cfscript>
/**
 * Internal GUI Routes
 * TODO: formalise how the cli interacts
 **/
mapper()
    .wildcard()
	.get(name="wheelstestbox", pattern="wheels/core/tests", to="wheels##public##tests_testbox")
	.get(name="sampleLinkToTest", pattern="sample/linktotest", to="sample##linktotest")
	.get(name="sampleLinkToTestTarget", pattern="sample/linktotesttarget", to="sample##linktotesttarget")
.end();

</cfscript>
