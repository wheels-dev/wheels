<cfscript>
	/*
		Use this file to configure your application.
		You can also use the environment specific files (e.g. app/config/production/settings.cfm) to override settings set here.
		Don't forget to issue a reload request (e.g. reload=true) after making changes.
		See https://wheels.dev/3.0.0/guides/working-with-wheels/configuration-and-defaults for more info.	*/

	/*
		You can change the "wheels.dev" value from the two functions below to set your datasource.
		You can change the the value for the "dataSourceName" to set a default datasource to be used throughout your application.
		You can also change the value for the "coreTestDataSourceName" to set your testing datasource.
		You can also uncomment the 2 "set" functions below them to set the username and password for the datasource.
	*/
	// set(coreTestDataSourceName="wheels.dev");
	// set(dataSourceUserName="");
	// set(dataSourcePassword="");

	/*
		If you comment out the following line, Wheels will try to determine the URL rewrite capabilities automatically.
		The "URLRewriting" setting can bet set to "on", "partial" or "off".
		To run with "partial" rewriting, the "cgi.path_info" variable needs to be supported by the web server.
		To run with rewriting set to "on", you need to apply the necessary rewrite rules on the web server first.
	*/
		// Reload your application with ?reload=true&password=changeme
	// Obviously, change this.
	set(reloadPassword="changeme");

	// Your Apps datasource name
	set(dataSourceName="starterApp");

	// Turn on new flashAppend Behaviour
	set(flashAppend = true);

	// Optional: Create SQL files when migrating
	// Useful for debugging
	// set(writeMigratorSQLFiles=true);

	// Turn on URL rewriting by default.
	// Commandbox urlrewrite.xml is provided.
	// See https://wheels.dev/guides/handling-requests-with-controllers/url-rewriting/README for Apache/IIS etc
	set(URLRewriting="On");

	// Don't include potentially sensitive data in error handling emails
	set(excludeFromErrorEmail="form.password,form.passwordHash,form.passwordResetToken");
	set(sendEmailOnError=false); // TODO: change this

	//=====================================================================
	//= 	Bootstrap 4 form settings
	//=====================================================================
	// Submit Tag
	set(functionName="submitTag", class="btn btn-primary", value="Save Changes");

	// Checkboxes and Radio Buttons
	set(functionName="hasManyCheckBox,checkBox,checkBoxTag", labelPlacement="aroundRight", prependToLabel="<div class='form-check'>", appendToLabel="</div>", uncheckedValue="0", encode="attributes", class="form-check-input");
	set(functionName="radioButton,radioButtonTag", labelPlacement="aroundRight", prependToLabel="<div class='radio'>", appendToLabel="</div>");

	// Text/select/password/file Fields
	set(functionName="textField,textFieldTag,select,selectTag,passwordField,passwordFieldTag,textArea,textAreaTag,fileFieldTag,fileField",
		class="form-control",
		labelClass="control-label",
		labelPlacement="before",
		prependToLabel="<div class='form-group'>",
		prepend="<div class=''>",
		append="</div></div>",
		encode="attributes"  );

	// Date Pickers
	set(functionName="dateTimeSelect,dateSelect", prepend="<div class='form-group'>", append="</div>", timeSeparator="", minuteStep="5", secondStep="10", dateOrder="day,month,year", dateSeparator="", separator="");

	// Pagination
	set(functionName="paginationLinks", prepend="<ul class='pagination'>", append="</ul>", prependToPage="<li class='page-item'>", appendToPage="</li>", linkToCurrentPage=true, classForCurrent="page-link active", class="page-link", anchorDivider="<li class='disabled'><a href='##''>...</a></li>", encode="attributes");

	// Error Messagss
	set(functionName="errorMessagesFor", class="alert alert-dismissable alert-danger");
	set(functionName="errorMessageOn", wrapperElement="div", class="alert alert-danger");

	// Password Fields
	set(functionName="passwordField,passwordFieldTag", autocomplete="off");

	// CLI-Appends-Here
</cfscript>
