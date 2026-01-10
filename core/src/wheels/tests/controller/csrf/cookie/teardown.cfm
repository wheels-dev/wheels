<cfscript>
application.wheels.csrfStore = $oldCsrfStore;

request.cgi.request_method = $oldRequestMethod;
request.cgi.http_x_requested_with = $oldHttpXRequestedWith;
StructDelete(request.$wheelsHeaders, "X-CSRF-TOKEN");
</cfscript>
