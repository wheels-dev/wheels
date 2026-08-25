<!--- S1: main seeds.cfm must actually create a record so runSeeds() is not a no-op. --->
<cfscript>
seedOnce(
	modelName = "author",
	uniqueProperties = "firstName",
	properties = {firstName: "SeederMainOK99", lastName: "MainSeed"}
);
</cfscript>
