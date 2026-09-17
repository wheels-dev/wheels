<!--- S7: first entry would persist if the include-throw catch did not roll back. --->
<cfscript>
seedOnce(
	modelName = "author",
	uniqueProperties = "firstName",
	properties = {firstName: "SeederThrowOK99", lastName: "ThrowOK"}
);
throw(type = "SeederIncludeBoom", message = "intentional include throw");
</cfscript>
