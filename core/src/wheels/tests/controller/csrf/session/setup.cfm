<cfscript>
$oldRequestMethod = request.cgi.request_method;
$oldHttpXRequestedWith = request.cgi.http_x_requested_with;
$oldCsrfStore = application.wheels.csrfStore;
application.wheels.csrfStore = "session";
</cfscript>
