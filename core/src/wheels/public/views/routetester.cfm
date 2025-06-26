<cfscript>
param name="request.wheels.params.path" default="/";
param name="request.wheels.params.verb" default="GET";
result = $$findMatchingRoutes(path = request.wheels.params.path, requestMethod = request.wheels.params.verb);
</cfscript>

<cfoutput>
	<!--- cfformat-ignore-start --->
	<div class="ui horizontal section divider">Results</div>

	<cfif ArrayLen(result.errors)>
		<h3>Route Errors (#ArrayLen(result.errors)#)</h3>

		<cfloop from="1" to="#ArrayLen(result.errors)#" index="err">
			<h4>#result.errors[err].type#</h4>
			<p>
				<strong>#result.errors[err].message#</strong>
			</p>
			<p>#result.errors[err].extendedInfo#</p>
		</cfloop>
	</cfif>

	<cfif ArrayLen(result.matches)>
		<h3>Route Matches (#ArrayLen(result.matches)#)</h3>

		<!--- High possible multiple matches --->
		<cfif ArrayLen(result.matches) GT 1>
			<div class="ui info message">
				<div class="header">Multiple potential matches</div>
					The path entered could possibly match multiple routes:
					<strong>CFWheels uses the first match in this table</strong>
					- the other routes are shown here for information only to help in your debugging, i.e when you're trying to work out why a route is loading incorrectly.
			</div>
		</cfif>

		<table class="ui celled striped table route-dump">
			<thead>
				<tr>
					<th class="right">Name</th>
					<th>Method</th>
					<th>Pattern</th>
					<th>Controller</th>
					<th>Action</th>
				</tr>
			</thead>
			<tbody>
				<cfloop from="1" to="#ArrayLen(result.matches)#" index="route">#outputRouteRow(result.matches[route])#</cfloop>
			</tbody>
		</table>
	</cfif>
	<!--- cfformat-ignore-end --->
</cfoutput>

