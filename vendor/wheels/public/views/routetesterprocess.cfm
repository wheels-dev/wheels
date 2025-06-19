<cfscript>
// Process route testing parameters
param name="request.wheels.params.path" default="/";
param name="request.wheels.params.verb" default="GET";

// Find matching routes using the internal framework function
result = $$findMatchingRoutes(
	path = request.wheels.params.path, 
	requestMethod = request.wheels.params.verb
);
</cfscript>

<cfoutput>
	<!--- cfformat-ignore-start --->
	<div class="ui segment">
		<h3>Route Test Results</h3>
		
		<div class="ui form">
			<div class="two fields">
				<div class="field">
					<label>Path Tested</label>
					<div class="ui input">
						<input type="text" value="#EncodeForHTML(request.wheels.params.path)#" readonly>
					</div>
				</div>
				<div class="field">
					<label>HTTP Method</label>
					<div class="ui input">
						<input type="text" value="#EncodeForHTML(request.wheels.params.verb)#" readonly>
					</div>
				</div>
			</div>
		</div>

		<cfif ArrayLen(result.errors)>
			<div class="ui negative message">
				<div class="header">Route Errors Found</div>
				<ul class="list">
					<cfloop array="#result.errors#" item="error">
						<li>
							<strong>#error.type#:</strong> #error.message#
							<cfif StructKeyExists(error, "extendedInfo") AND Len(error.extendedInfo)>
								<br><small>#error.extendedInfo#</small>
							</cfif>
						</li>
					</cfloop>
				</ul>
			</div>
		</cfif>

		<cfif ArrayLen(result.matches)>
			<div class="ui positive message">
				<div class="header">Matching Routes Found</div>
				<p>#ArrayLen(result.matches)# route(s) matched your request.</p>
			</div>

			<table class="ui celled table">
				<thead>
					<tr>
						<th>Route Name</th>
						<th>HTTP Method</th>
						<th>Pattern</th>
						<th>Controller</th>
						<th>Action</th>
					</tr>
				</thead>
				<tbody>
					<cfloop array="#result.matches#" item="match">
						<tr>
							<td>#StructKeyExists(match, "name") ? match.name : "N/A"#</td>
							<td>#StructKeyExists(match, "method") ? match.method : "N/A"#</td>
							<td>#StructKeyExists(match, "pattern") ? match.pattern : "N/A"#</td>
							<td>#StructKeyExists(match, "controller") ? match.controller : "N/A"#</td>
							<td>#StructKeyExists(match, "action") ? match.action : "N/A"#</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		<cfelse>
			<div class="ui warning message">
				<div class="header">No Matching Routes</div>
				<p>No routes matched the specified path and HTTP method.</p>
			</div>
		</cfif>
	</div>
	<!--- cfformat-ignore-end --->
</cfoutput>