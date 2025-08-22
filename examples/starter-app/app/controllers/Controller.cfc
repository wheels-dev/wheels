/**
 * This is the parent controller file that all your controllers should extend.
 * You can add functions to this file to make them available in all your controllers.
 * Do not delete this file.
 *
 * NOTE: When extending this controller and implementing `config()` in the child controller, don't forget to call this
 * base controller's `config()` via `super.config()`, or else the call to `protectsFromForgery` below will be skipped.
 *
 * Example controller extending this one:
 *
 * component extends="Controller" {
 *   function config() {
 *     // Call parent config method
 *     super.config();
 *
 *     // Your own config code here.
 *     // ...
 *   }
 * }
 */
component extends="wheels.Controller" {
	/**
	 * Base controller config method to set up security, access control, and logging filters.
	 *
	 * @param boolean protectFromForgery Enable CSRF protection (default: true)
	 * @param boolean restrictAccess Require permission to access this controller (default: false)
	 * @param boolean redirectAuthenticatedUsers Redirect logged-in users away (default: false)
	 * @param boolean logFlash Log flash messages in audit log (default: true)
	 */
	function config(
		boolean protectFromForgery=true,
		boolean restrictAccess=false,
		boolean redirectAuthenticatedUsers=false,
		boolean logFlash=true
	) {
		try {
			// Enable CSRF protection if requested
			if(arguments.protectFromForgery){
				protectsFromForgery();
			}
			// Require permission to access this controller
			if(arguments.restrictAccess){
				filters(through="checkPermissionAndRedirect");
			}
			// Redirect authenticated users away from this controller
			if(arguments.redirectAuthenticatedUsers){
				filters(through="redirectAuthenticatedUsers");
			}
			// Log flash messages after actions
			if(arguments.logFlash){
				filters(through="logFlash", type="after");
			}
			// Check for password reset blocks
			filters(through="checkForPasswordBlock");
		} catch(any e) {
			// Log error and rethrow
			addLogLine(type="controller", message="Error in base controller config: #e.message#", severity="danger");
			rethrow;
		}
	}

	// Include controller-wide shared functions for authentication and filters
	include "functions/auth.cfm";
	include "functions/filters.cfm";
}
