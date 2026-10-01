<cfscript>
// Settings for the "production" environment only. They run after
// config/settings.cfm, so a value set here overrides the shared one.
// Only name the keys this environment changes.
//
// Error emails (sendEmailOnError is on in production) go only to an address
// you configure; with none set, no error email is sent. Example:
// set(errorEmailAddress = "ops@example.com");
</cfscript>
