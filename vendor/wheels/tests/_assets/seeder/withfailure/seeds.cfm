<!--- Test seed file for seederSpec (withfailure) --->
<!--- Exercises the partial-failure rollback path: one valid entry --->
<!--- followed by one that fails validation. The whole transaction --->
<!--- must roll back. --->
<cfscript>
// Successful entry — must be rolled back when the next one fails.
seedOnce(
	modelName = "author",
	uniqueProperties = "firstName,lastName",
	properties = {firstName: "SeederRollbackOK", lastName: "SeederRollbackMarker"}
);

// Failing entry — user model requires username, password, firstname, lastname.
// Supplying only username forces validation failure → action="failed".
seedOnce(
	modelName = "user",
	uniqueProperties = "username",
	properties = {username: "SeederPartialFailureTestUser"}
);
</cfscript>
