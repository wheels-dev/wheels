<cfoutput>
<h1>wheels-sentry</h1>
<p>Sentry error tracking for CFWheels with framework-aware context enrichment.</p>
<h2>Status</h2>
<table class="table">
	<tr><td><strong>Version</strong></td><td>1.0.0</td></tr>
	<tr><td><strong>DSN Configured</strong></td><td>#YesNoFormat(StructKeyExists(application, "sentry"))#</td></tr>
	<tr>
		<td><strong>Environment</strong></td>
		<td>#(StructKeyExists(application, "sentry") ? application.sentry.getEnvironment() : "N/A")#</td>
	</tr>
</table>
<h2>Available Methods</h2>
<ul>
	<li><code>sentryCapture(exception, [tags], [level])</code> — Capture exception with context</li>
	<li><code>sentryMessage(message, [level], [tags])</code> — Capture message event</li>
	<li><code>sentrySetUser(userStruct)</code> — Set user context for request</li>
	<li><code>sentryAddBreadcrumb(message, [category], [level], [data])</code> — Add breadcrumb</li>
</ul>
</cfoutput>
