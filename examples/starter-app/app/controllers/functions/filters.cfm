<cfscript>
//=====================================================================
//= 	Miscellaneous Filters
//=====================================================================
	/**
	* Sets the `roles` variable with all available roles
	*
	* [section: Application]
	* [category: Filters]
	*/
	private function filterGetAllRoles() {
		roles=model("role").getRolesOrderBy();
	}

	/**
	* Logs the output of the flash scope: used as a filter
	*
	* [section: Application]
	* [category: Filters]
	*/
	private function logFlash(){
		// Don't log if testing
		if(!structKeyExists(request, "isTestMode") && structkeyexists(session,"flash")){
			if(structkeyexists(session.flash, "error")){
				addLogLine(message=session.flash.error, type="flash", severity="danger");
			}
			if(structkeyexists(session.flash, "success")){
				addLogLine(message=session.flash.success, type="flash", severity="success");
			}
			if(structkeyexists(session.flash, "info")){
				addLogLine(message=session.flash.info, type="flash", severity="info");
			}
		}
	}

	/**
	* Confirms that the current request is being done via Ajax
	*
	* [section: Application]
	* [category: Filters]
	*/
	private function isAjaxRequest() {
		if(!isAjax()){
			writeOutput("Invalid Request"); abort;
		}
	}

	/**
	* Main Filter to Test for the session flag for a required password change
	* We still allow access to the main facility to update their password, and also
	* to logout, but nothing else.
	*
	* [section: Application]
	* [category:Filters]
	*/
	private function checkForPasswordBlock(){
	    if(isAuthenticated()
	    	&& hasPasswordResetBlock()
	    	&& params.route != 'accountPassword'
	    	&& params.route != 'logout'
	    ){
	    	redirectTo(route="accountPassword");
	    }
	}

</cfscript>
