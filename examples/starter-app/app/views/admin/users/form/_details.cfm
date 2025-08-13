<cfoutput>
#panel(title="User Details", class="mb-2")#
	<div class="row">
		<div class="col-12 col-sm">
			#textField(objectName="user", property="firstname", label="First Name")#
		</div>
		<div class="col-12 col-sm">
			#textField(objectName="user", property="lastname", label="Last Name")#
		</div>
	</div>
	<div class="row">
		<div class="col-12 col-sm">
			#textField(objectName="user", property="email", label="Email Address")#
		</div>
	</div>
	<cfif hasPermission("canViewAdminNotes")>
		<div class="row">
			<div class="col-12 col-sm">
				#textArea(objectName="user", property="adminNotes", label="Administrative Notes")#
				<small id="passwordHelpBlock" class="form-text text-muted">These can only be seen by those with the appropriate permission</small>
			</div>
		</div>
	</cfif>
#panelEnd()#
</cfoutput>
