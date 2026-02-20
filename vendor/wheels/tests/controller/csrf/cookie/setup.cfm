<cfscript>
$oldCsrfStore = application.wheels.csrfStore;
application.wheels.csrfStore = "cookie";

$oldRequestMethod = request.cgi.request_method;
$oldHttpXRequestedWith = request.cgi.http_x_requested_with;
csrfToken = controller("dummy").$readAuthenticityTokenFromCookie();
</cfscript>
