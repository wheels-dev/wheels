/*
	You can place ".cfm" files in this folder and run them independently from Wheels.
	This empty "Application.cfc" file makes sure that CFWheels does not interfere with the request.
*/
component {

	this.name = Hash(
		GetDirectoryFromPath(
			Left(GetBaseTemplatePath(), Len(GetBaseTemplatePath()) - Len("/wheels/tests/_assets/sharedappname/test.cfm"))
		)
	);

}
