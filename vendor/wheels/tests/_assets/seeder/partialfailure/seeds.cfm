<!--- Test seed file for seederSpec's partial-failure path: the first entry
saves cleanly, the second fails validation (the User model requires
username, password, firstname and lastname — the second entry omits
password) so the run must report failure and roll back the first entry
too. --->
<cfscript>
seedOnce(
	modelName = "user",
	uniqueProperties = "username",
	properties = {
		username: "SeederPartialOK99",
		password: "seedpass",
		firstname: "Seeder",
		lastname: "PartialOK"
	}
);
seedOnce(
	modelName = "user",
	uniqueProperties = "username",
	properties = {username: "SeederPartialBad99", firstname: "Seeder", lastname: "PartialBad"}
);
</cfscript>
