<cfcomponent extends="types.Driver" implements="types.IDatasource">

	<cfset fields=array(
		field(
			"Database File Path",
			"path",
			"",
			true,
			"Absolute path to the SQLite database file. The file is created automatically if it doesn't exist. Use ':memory:' for an in-memory database."
		)
	)>

	<cfset this.type.host=this.TYPE_HIDDEN>
	<cfset this.type.port=this.TYPE_HIDDEN>
	<cfset this.type.database=this.TYPE_HIDDEN>
	<cfset this.type.username=this.TYPE_HIDDEN>
	<cfset this.type.password=this.TYPE_HIDDEN>

	<cfset this.dsn="jdbc:sqlite:{path}">
	<cfset this.className="org.sqlite.JDBC">
	<cfset this.bundleName="org.xerial.sqlite-jdbc">

	<cfscript>
		string function getDSN() output="no" {
			var _path = trim(form.custom_path ?: "");
			if (len(_path) == 0) {
				throw message="[path] is required for the SQLite driver. Provide an absolute path to a database file, or ':memory:' for an in-memory database.";
			}
			if (_path == ":memory:") {
				return "jdbc:sqlite::memory:";
			}
			return "jdbc:sqlite:" & _path;
		}
	</cfscript>

	<cffunction name="getName" returntype="string" output="no"
		hint="returns display name of the driver">
		<cfreturn "SQLite">
	</cffunction>

	<cffunction name="getId" returntype="string" output="no"
		hint="returns the ID of the driver">
		<cfreturn "sqlite">
	</cffunction>

	<cffunction name="getDescription" returntype="string" output="no"
		hint="returns description for the driver">
		<cfreturn "SQLite JDBC driver (xerial sqlite-jdbc). Embedded, file-based or in-memory SQL database with no external service. Ideal for development, tests, single-user apps, and Wheels' default datasource.">
	</cffunction>

	<cffunction name="getFields" returntype="array" output="no"
		hint="returns array of fields">
		<cfreturn fields>
	</cffunction>

</cfcomponent>
