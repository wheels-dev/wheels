<!--- Product Index --->
<cfparam name="products">
<cfoutput>
	<h1>Products index</h1>
	<p>#linkTo(route="newProduct", text="Create New Product", class="btn btn-default")#</p>

	<cfif products.recordcount>
		<table class="table">
			<thead>
				<tr>
					<th>ID</th>
                    <!--- CLI-Appends-thead-Here --->
					<th>Actions</th>
				</tr>
			</thead>
			<tbody>
				<cfloop query="products">
				<tr>
					<td>
						#id#
					</td>
                    <!--- CLI-Appends-tbody-Here --->
					<td>
						<div class="btn-group">
							#linkTo(route="Product", key=id, text="View", class="btn btn-xs btn-info", encode=false)#
							#linkTo(route="editProduct", key=id, text="Edit", class="btn btn-xs btn-primary", encode=false)#
						</div>
						#buttonTo(route="Product", method="delete", key=id, text="Delete", class="pull-right", inputClass="btn btn-danger btn-xs", encode=false)#
					</td>
				</tr>
				</cfloop>
			</tbody>
		</table>
	<cfelse>
		<p>Sorry, there are no Products yet</p>
	</cfif>
</cfoutput>
