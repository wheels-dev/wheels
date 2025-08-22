<cfoutput>
#panel(title="User Options", class="mb-2")#
<div class="row">
	<div class="col-12 col-sm">
		#select(objectName="user", property="roleid", options=roles, label="Role")#
	</div>
	<div class="col-12 col-sm">
		#checkBox(objectname="user", property="verified", label="Verified")#
		#checkbox(objectName="user", property="passwordchangerequired", label="Require Change of Password on Next Login")#
	</div>
</div>
#panelEnd()#
</Cfoutput>

