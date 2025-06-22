<cfcomponent extends="wheels.migrator.Migration" hint="create bunyips table">
	<cffunction name="up">
		<cfset hasError = false/>
		<cftransaction>
			<cfscript>
			try {
				t = createTable(name = "bunyips");
				t.string(columnNames = "name", default = "", null = true, limit = 255);
				t.timestamps();
				t.create();
			} catch (any ex) {
				hasError = true;
				catchObject = ex;
			}
			</cfscript>
			<cfif hasError>
				<cftransaction action="rollback"/>
				<cfthrow detail="#catchObject.detail#" errorCode="1" message="#catchObject.message#" type="Any">
			<cfelse>
				<cftransaction action="commit"/>
			</cfif>
		</cftransaction>
	</cffunction>
	<cffunction name="down">
		<cfset hasError = false/>
		<cftransaction>
			<cfscript>
			try {
				dropTable('bunyips');
			} catch (any ex) {
				hasError = true;
				catchObject = ex;
			}
			</cfscript>
			<cfif hasError>
				<cftransaction action="rollback"/>
				<cfthrow detail="#catchObject.detail#" errorCode="1" message="#catchObject.message#" type="Any">
			<cfelse>
				<cftransaction action="commit"/>
			</cfif>
		</cftransaction>
	</cffunction>
</cfcomponent>
