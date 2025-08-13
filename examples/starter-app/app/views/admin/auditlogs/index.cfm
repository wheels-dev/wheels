<cfparam name="auditlogs">
<cfoutput>
 	#pageHeader(title="Logs")#
 	#includePartial("filter")#
 	#panel(title="Audit Log", class="mb-4")#

	<cfif auditlogs.recordcount>
		<div class="table-responsive">
			<table class="table table-sm">
				<thead>
					<tr>
						<th>Type</th>
						<th>Message</th>
						<th>IP</th>
						<!---th>Data</th--->
						<th>By</th>
						<th>Date</th>
					</tr>
				</thead>
				<tbody>
					<cfloop query="auditlogs">
						<tr>
							<td>#logFileBadge(type=type, severity=severity)#</td>
							<td><small>
								<cfif hasPermission("canViewLogData") && isJson(data)>
									<a href="##" title="View Data" data-toggle="modal" data-target="##logModalCenter" data-remoteurl=#urlFor(route='log', format='json', key=id)#>#e(Message)#</a>
								<cfelse>
									#e(Message)#
								</cfif>
							</small>
							</td>
							<td><small>#e(IPaddress)#</small></td>
							<td><small title="#e(createdBy)#">#truncate(e(createdBy), 14)#</small></td>
							<td class="text-nowrap"><small title="#timeAgoInWords(createdAt)# ago">#formatDate(createdAt)#</small></td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
		#paginationLinks(route="logs")#
	<cfelse>
		<div class="alert alert-info">
			<strong>Sorry</strong><br /> there are no Logs to display
		</div>
	</cfif>
 	#panelEnd()#

 	#includePartial("modal")#
</cfoutput>
