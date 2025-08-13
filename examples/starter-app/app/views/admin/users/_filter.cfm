<!--- User Search/Filter --->
<cfparam name="roles">
<cfparam name="params.q">
<cfparam name="params.roleid">
<cfparam name="params.status">
<cfoutput>
#startFormTag(route="users", method="get", class="form-inline mb-2")#
	<div class="row">
	    <div class="col-12 col-sm">
				#selectTag(name="roleid", options=roles, includeBlank="All Roles", selected=params.roleid, label="Role", prependToLabel="<div class=""form-group mb-2"">", labelClass="sr-only")#
		</div>
	    <div class="col-12 col-sm">
			 #selectTag(name="status", options="Active,Pending,Disabled,All",  selected=params.status, label="Status", prependToLabel="<div class=""form-group mb-2"">", labelClass="sr-only")#
		</div>

		<div class="col-12 col-sm">
			#textFieldTag(name="q", value=params.q, label="Keyword Search", labelClass="sr-only", placeholder="Keyword")#
		</div>

	    <div class="col-12 col-sm">
			#submitTag(value="Filter", class="btn btn-info text-white")#
		</div>
	</div>
#endFormTag()#
</cfoutput>
