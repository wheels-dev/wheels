<cfscript>
// Split out internal routes
"routes" = {
	"internalRoutes" = [],
	"appRoutes" = []
};

for (r in application.wheels.routes){
	if ((StructKeyExists(r, "controller") && r.controller EQ "wheels.public") || (StructKeyExists(r, "pattern") && r.pattern eq "/wheels/app/tests")) {
		ArrayAppend(routes.internalRoutes, r);
	} else {
		ArrayAppend(routes.appRoutes, r);
	}
}
</cfscript>
<!--- cfformat-ignore-start --->
<cfinclude template="../layout/_header.cfm">

<cfoutput>

<div class="ui container">

#pageHeader("Routes", "What's going where..")#

<div class="ui top attached tabular menu stackable">
	<a class="item active" data-tab="appRoutes">App&nbsp;<span class="route-count">(#NumberFormat(ArrayLen(routes.appRoutes))#)</span></a>
	<a class="item" data-tab="internalRoutes">Internal&nbsp;<span class="route-count">(#NumberFormat(ArrayLen(routes.internalRoutes))#)</span></a>
</div>

<cfloop collection="#routes#" item="type">
#startTab(tab=type, active=type EQ 'appRoutes' ? true:false)#

<cfif type EQ "internalRoutes">

	<div class="ui info message">
		<div class="header">
			Note
		</div>
		These are here for reference only. They aren't loaded in production, and only used to render the CFWheels internal interface
	</div>

<cfelse>

	<div class="ui stackable grid">
		<div class="two column row">
			<div class="column">
			<!--- Route Filter --->
			<div class="ui fluid action input">
				<input type="text" name="route-search" id="route-search" class="table-searcher" placeholder="Quick find...">
					<button class="ui icon button matched-count">
						<svg xmlns="http://www.w3.org/2000/svg" height="16" width="16" viewBox="0 0 512 512"><path fill="##7e7e7f" d="M505 442.7L405.3 343c-4.5-4.5-10.6-7-17-7H372c27.6-35.3 44-79.7 44-128C416 93.1 322.9 0 208 0S0 93.1 0 208s93.1 208 208 208c48.3 0 92.7-16.4 128-44v16.3c0 6.4 2.5 12.5 7 17l99.7 99.7c9.4 9.4 24.6 9.4 33.9 0l28.3-28.3c9.4-9.4 9.4-24.6 .1-34zM208 336c-70.7 0-128-57.2-128-128 0-70.7 57.2-128 128-128 70.7 0 128 57.2 128 128 0 70.7-57.2 128-128 128z"/></svg>
					<span class="matched-count-value"></span>
				</button>
			</div>
			</div>
			<div class="column">
			<!--- Route Tester --->
			<div class="ui fluid action input">
				<input type="text" id="route-tester-path" placeholder="/example/path" />
				<select id="route-tester-verb" class="ui select dropdown">
					<option value="GET" selected>GET</option>
					<option value="POST">POST</option>
					<option value="PUT">PUT</option>
					<option value="PATCH">PATCH</option>
					<option value="DELETE">DELETE</option>
					<option value="HEAD">HEAD</option>
					<option value="OPTIONS">OPTIONS</option>
				</select>
				<button class="ui button route-test teal" data-test-url="#urlFor(route='wheelsRouteTester')#" >Test</button>
			</div>
			</div>
		</div>
	</div>

	<div id="router-tester-results"></div>

</cfif>
<div class="ui horizontal section divider">
	Routes
</div>
<div style="overflow-x: scroll;">
	<table class="ui celled striped table searchable">
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
			<cfloop array="#routes[type]#" index="route">
				#outputRouteRow(route)#
			</cfloop>
		</tbody>
	</table>
</div>

#endTab()#
</cfloop>

</div>

</cfoutput>

<cfinclude template="../layout/_footer.cfm">
<!--- cfformat-ignore-end --->
