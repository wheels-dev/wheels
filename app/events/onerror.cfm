<cfscript>
	// Log the error to stderr so it appears in server logs / container output.
	// The exception struct is passed into scope by the framework's $runOnError().
	local.message = "ERROR";
	if (StructKeyExists(variables, "exception")) {
		if (StructKeyExists(exception, "rootCause") && StructKeyExists(exception.rootCause, "message")) {
			local.message = ToString(exception.rootCause.type) & ": " & ToString(exception.rootCause.message);
		} else if (StructKeyExists(exception, "message")) {
			local.message = exception.message;
		}
	}
	cflog(text = local.message, type = "error", file = "wheels-errors");
	WriteLog(type = "Error", text = local.message);
</cfscript>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>Something went wrong</title>
	<style>
		body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: ##f8f9fa; color: ##333; }
		.container { text-align: center; max-width: 480px; padding: 2rem; }
		h1 { font-size: 1.5rem; margin-bottom: 0.5rem; }
		p { color: ##666; line-height: 1.6; }
	</style>
</head>
<body>
	<div class="container">
		<h1>Something went wrong</h1>
		<p>We encountered an unexpected error processing your request. The issue has been logged and our team will look into it.</p>
		<p><a href="/">Return to homepage</a></p>
	</div>
</body>
</html>
