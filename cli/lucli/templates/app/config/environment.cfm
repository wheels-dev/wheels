<cfscript>
// Use this file to set the current environment for your application.
// You can set it to "development", "testing", "maintenance" or "production".
// Don't forget to issue a reload request (e.g. reload=true) after making changes.
// See https://guides.wheels.dev/v4-2-0/core-concepts/environments-and-configuration/ for more info.

// The environment comes from WHEELS_ENV: the value in .env if it has one, otherwise the
// process environment (a Dockerfile ENV, a systemd unit, your deploy script).
// Unset or empty means "development", so a new app runs locally with no setup; set
// WHEELS_ENV=production for a live app. Any other value stops the app from starting
// rather than running with development-style error output.
local.wheelsEnvironment = Trim(env("WHEELS_ENV", ""));
if (!Len(local.wheelsEnvironment)) {
	local.wheelsEnvironment = "development";
}
if (!ListFindNoCase("development,testing,maintenance,production", local.wheelsEnvironment)) {
	Throw(
		type = "Wheels.InvalidEnvironment",
		message = "WHEELS_ENV must be development, testing, maintenance or production.",
		detail = "WHEELS_ENV is set to """ & local.wheelsEnvironment & """."
	);
}
set(environment=LCase(local.wheelsEnvironment));
</cfscript>
