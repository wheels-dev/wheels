<cfscript>
public any function $cleanSqlDirectory() {
	local.path = migrator.paths.sql;
	if (DirectoryExists(local.path)) {
		DirectoryDelete(local.path, true);
	}
}
</cfscript>
