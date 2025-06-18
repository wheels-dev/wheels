<cfscript>
public void function deleteMigratorVersions(required numeric levelId) {
	queryExecute(
		"DELETE FROM _c_o_r_e_migrator_versions WHERE core_level = :levelId",
		{
			levelId = {
				value      = arguments.levelId,
				cfsqltype  = "cf_sql_integer"
			}
		},
		{ datasource = application.wheels.dataSourceName }
	);
}

public any function $cleanSqlDirectory() {
	local.path = migrator.paths.sql;
	if (DirectoryExists(local.path)) {
		DirectoryDelete(local.path, true);
	}
}
</cfscript>
