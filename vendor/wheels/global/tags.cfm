<cfscript>
/**
 * wheels.Global include: tags
 * CFML tag wrappers (cfheader, cfmail, cfinclude, cfdbinfo, …).
 *
 * Included from `vendor/wheels/Global.cfc` at component-body scope so
 * these functions compile into the Global component. Children inherit
 * them; there is no per-instance mixin copy. Keep every helper that
 * must mix onto models/controllers `public` and `$`-prefixed
 * (cross-engine invariant 7).
 */


	public struct function $image() {
		local.rv = {};
		if (arguments.action == "info") {
			local.rv = $engineAdapter().imageInfo(arguments.source);
		} else if ($engineAdapter().isBoxLang()) {
			Throw(
				type = "Wheels.Image.UnsupportedAction",
				message = "The `$image()` function in BoxLang currently supports only the 'info' action."
			);
		} else {
			// Adobe or Lucee: use cfimage
			arguments.structName = "rv";
			local.args = {};
			for (local.key in arguments) {
				local.args[local.key] = arguments[local.key];
			}
			cfimage(attributeCollection = local.args);
			local.rv = local.rv;
		}
		return local.rv;
	}


	public void function $mail() {
		if (StructKeyExists(arguments, "mailparts")) {
			local.mailparts = arguments.mailparts;
			StructDelete(arguments, "mailparts");
		}
		if (StructKeyExists(arguments, "mailparams")) {
			local.mailparams = arguments.mailparams;
			StructDelete(arguments, "mailparams");
		}
		if (StructKeyExists(arguments, "tagContent")) {
			local.tagContent = arguments.tagContent;
			StructDelete(arguments, "tagContent");
		}
		local.args = {};
		for (local.key in arguments) {
			local.args[local.key] = arguments[local.key];
		}
		cfmail(attributeCollection = "#local.args#") {
			if (StructKeyExists(local, "mailparams")) {
				for (local.i in local.mailparams) {
					cfmailparam(attributeCollection = "#local.i#");
				}
			}
			if (StructKeyExists(local, "mailparts")) {
				for (local.i in local.mailparts) {
					local.innerTagContent = local.i.tagContent;
					StructDelete(local.i, "tagContent");
					cfmailpart(attributeCollection = "#local.i#") {
						WriteOutput(local.innerTagContent)
					}
				}
			}
			if (StructKeyExists(local, "tagContent")) {
				WriteOutput(local.tagContent)
			}
		}
	}


	public any function $cache() {
		// If cache is found only the function is aborted, not page. --->
		variables.$instance.reCache = false;
		// Engines without the `cfcache` built-in (e.g. RustCFML) can't back
		// the template/static cache. Degrade to a no-op: leaving reCache=true
		// means the request still renders normally, just without this layer.
		if ($hasEngineAdapter() && !$engineAdapter().supportsCfcache()) {
			variables.$instance.reCache = true;
			return;
		}
		local.args = {};
		for (local.key in arguments) {
			local.args[local.key] = arguments[local.key];
		}
		cfcache(attributeCollection = "#local.args#");
		variables.$instance.reCache = true;
	}


	public void function $content() {
		local.args = {};
		for (local.key in arguments) {
			local.args[local.key] = arguments[local.key];
		}
		// Best-effort: cfcontent throws on a committed response (Adobe CF).
		if ($responseCommitted()) {
			return;
		}
		try {
			cfcontent(attributeCollection = "#local.args#");
		} catch (any e) {
			// Re-probe to handle the isCommitted/throw race; rethrow only when
			// the response is still uncommitted (a genuine caller error).
			if (!$responseCommitted()) {
				rethrow;
			}
		}
	}


	public void function $header() {
		// Plain-struct copy: Adobe CF 2023+ rejects `arguments` as
		// attributeCollection (#10 cross-engine invariant). `statusText` is
		// stripped because Adobe CF 2025 removed it.
		local.args = {};
		for (local.key in arguments) {
			if (local.key != "statusText") {
				local.args[local.key] = arguments[local.key];
			}
		}
		// Best-effort: cfheader throws on a committed response (Adobe CF). The
		// short-circuit is critical inside onError, where letting the exception
		// escape would replace the original error with the cfheader-failure stack.
		if ($responseCommitted()) {
			return;
		}
		try {
			cfheader(attributeCollection = "#local.args#");
		} catch (any e) {
			// Re-probe to handle the isCommitted/throw race; rethrow only when
			// the response is still uncommitted (a genuine caller error).
			if (!$responseCommitted()) {
				rethrow;
			}
		}
	}


	/**
	 * Returns true when the servlet response has been committed and headers
	 * can no longer be modified. Returns false on engines or contexts where
	 * the underlying servlet probe is unavailable.
	 */
	public boolean function $responseCommitted() {
		try {
			return GetPageContext().getResponse().isCommitted();
		} catch (any e) {
			return false;
		}
	}


	public any function $directory() {
		local.rv = "";
		arguments.name = "rv";
		local.args = {};
		for (local.key in arguments) {
			local.args[local.key] = arguments[local.key];
		}
		cfdirectory(attributeCollection = "#local.args#");
		return local.rv;
	}


	public any function $file() {
		local.args = {};
		for (local.key in arguments) {
			local.args[local.key] = arguments[local.key];
		}
		cffile(attributeCollection = "#local.args#");
	}


	public any function $cfinvoke(required string component, required string method, struct invokeArguments) {
		cfinvoke
		component = "#arguments.component#"
		method = "#arguments.method#"
		returnVariable = "#arguments.returnVariable#"
		argumentCollection = "#arguments.invokeArguments#";
		return local.rv;
	}


	public any function $invoke() {
		arguments.returnVariable = "local.rv";
		if (StructKeyExists(arguments, "componentReference")) {
			arguments.component = arguments.componentReference;
			StructDelete(arguments, "componentReference");
		} else if (NOT StructKeyExists(variables, arguments.method)) {
			// this is done so that we can call dynamic methods via "onMissingMethod" on the object (we need to pass in the object for this so it can call methods on the "this" scope instead)
			arguments.component = this;
		}
		if (StructKeyExists(arguments, "invokeArgs")) {
			arguments.argumentCollection = arguments.invokeArgs;
			if (StructCount(arguments.argumentCollection) IS NOT ListLen(StructKeyList(arguments.argumentCollection))) {
				// work-around for fasthashremoved cf8 bug
				arguments.argumentCollection = StructNew();
				for (local.i in StructKeyList(arguments.invokeArgs)) {
					arguments.argumentCollection[local.i] = arguments.invokeArgs[local.i];
				}
			}


			if (StructKeyExists(arguments.invokeArgs, "componentReference")) {
				arguments.component = arguments.invokeArgs.componentReference;
			}


			StructDelete(arguments, "invokeArgs");
		}
		local.args = {};
		for (local.key in arguments) {
			local.args[local.key] = arguments[local.key];
		}
		cfinvoke(attributeCollection = "#local.args#");
		if (StructKeyExists(local, "rv")) {
			return local.rv;
		}
	}


	public void function $location(boolean delay = false) {
		StructDelete(arguments, "$args", false);
		if (NOT arguments.delay) {
			StructDelete(arguments, "delay", false);
			local.args = {};
			for (local.key in arguments) {
				local.args[local.key] = arguments[local.key];
			}
			cflocation(attributeCollection = "#local.args#");
		}
	}


	public void function $htmlhead() {
		local.args = {};
		for (local.key in arguments) {
			local.args[local.key] = arguments[local.key];
		}
		// Best-effort: cfhtmlhead throws "Unable to add text to HTML HEAD tag"
		// on a committed response (Adobe CF). Same defensive shape as $header().
		if ($responseCommitted()) {
			return;
		}
		try {
			cfhtmlhead(attributeCollection = "#local.args#");
		} catch (any e) {
			// Re-probe to handle the isCommitted/throw race; rethrow only when
			// the response is still uncommitted (a genuine caller error).
			if (!$responseCommitted()) {
				rethrow;
			}
		}
	}


	public any function $dbinfo() {
		arguments.name = "local.rv";
		if (StructKeyExists(arguments, "username") && !Len(arguments.username)) {
			StructDelete(arguments, "username");
		}
		if (StructKeyExists(arguments, "password") && !Len(arguments.password)) {
			StructDelete(arguments, "password");
		}

		// BoxLang specific fix for index queries (MSSQL/Oracle)
		if (
			$engineAdapter().isBoxLang() &&
			StructKeyExists(arguments, "type") && arguments.type == "index" &&
			StructKeyExists(arguments, "table")
		) {
			local.adapter = $get("adapterName");

			if (local.adapter == "MicrosoftSQLServerModel") {
				local.sql = "
					SELECT
						DB_NAME() AS TABLE_CAT,
						SCHEMA_NAME(t.schema_id) AS TABLE_SCHEM,
						t.name AS TABLE_NAME,
						CAST(CASE WHEN i.is_unique = 0 THEN 1 ELSE 0 END AS INT) AS NON_UNIQUE,
						t.name AS INDEX_QUALIFIER,
						i.name AS INDEX_NAME,
						CASE
							WHEN i.type = 1 THEN 'Clustered Index'
							WHEN i.type = 2 THEN 'Other Index'
							ELSE 'Other Index'
						END AS TYPE,
						CAST(ic.key_ordinal AS INT) AS ORDINAL_POSITION,
						c.name AS COLUMN_NAME,
						CASE WHEN ic.is_descending_key = 0 THEN 'A' ELSE 'D' END AS ASC_OR_DESC,
						CAST(0 AS INT) AS CARDINALITY,
						CAST(0 AS INT) AS PAGES,
						'' AS FILTER_CONDITION
					FROM sys.indexes i
					INNER JOIN sys.objects t ON i.object_id = t.object_id
					INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
					INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
					WHERE t.name = '#arguments.table#'
						AND t.type = 'U'
						AND i.type_desc IN ('CLUSTERED', 'NONCLUSTERED')
					ORDER BY i.name, ic.key_ordinal
				";
				local.rv = $query(sql = local.sql, datasource = arguments.datasource);
				return local.rv;
			}

			if (local.adapter == "OracleModel") {
				local.sql = "
					SELECT
						NULL AS TABLE_CAT,
						ai.OWNER AS TABLE_SCHEM,
						ai.TABLE_NAME,
						CASE WHEN ai.UNIQUENESS = 'NONUNIQUE' THEN 1 ELSE 0 END AS NON_UNIQUE,
						ai.OWNER AS INDEX_QUALIFIER,
						ai.INDEX_NAME,
						'Other Index' AS TYPE,
						ac.COLUMN_POSITION AS ORDINAL_POSITION,
						ac.COLUMN_NAME,
						CASE WHEN ac.DESCEND = 'DESC' THEN 'D' ELSE 'A' END AS ASC_OR_DESC,
						0 AS CARDINALITY,
						0 AS PAGES,
						'' AS FILTER_CONDITION
					FROM ALL_INDEXES ai
					JOIN ALL_IND_COLUMNS ac ON ai.INDEX_NAME = ac.INDEX_NAME AND ai.OWNER = ac.INDEX_OWNER
					WHERE ai.TABLE_NAME = UPPER('#arguments.table#')
						AND ai.INDEX_TYPE != 'LOB'
					ORDER BY ai.INDEX_NAME, ac.COLUMN_POSITION
				";
				local.rv = $query(sql = local.sql, datasource = arguments.datasource);
				return local.rv;
			}
		}

		if (
			StructKeyExists(arguments, "type") &&
			arguments.type eq "index" &&
			$get("adapterName") eq "SQLiteModel"
		) {
			local.sql = "
				SELECT
					NULL AS TABLE_CAT,
					NULL AS TABLE_SCHEM,
					'#arguments.table#' AS TABLE_NAME,
					CASE WHEN il.""unique"" = 0 THEN 1 ELSE 0 END AS NON_UNIQUE,
					NULL AS INDEX_QUALIFIER,
					il.name AS INDEX_NAME,
					'Other Index' AS TYPE,
					ii.seqno + 1 AS ORDINAL_POSITION,
					ii.name AS COLUMN_NAME,
					'A' AS ASC_OR_DESC,
					0 AS CARDINALITY,
					0 AS PAGES,
					'' AS FILTER_CONDITION
				FROM pragma_index_list('#arguments.table#') il
				JOIN pragma_index_info(il.name) ii

				UNION ALL

				SELECT
					NULL AS TABLE_CAT,
					NULL AS TABLE_SCHEM,
					'#arguments.table#' AS TABLE_NAME,
					0 AS NON_UNIQUE,
					NULL AS INDEX_QUALIFIER,
					'PRIMARY' AS INDEX_NAME,
					'Primary Key' AS TYPE,
					pk AS ORDINAL_POSITION,
					name AS COLUMN_NAME,
					'A' AS ASC_OR_DESC,
					0 AS CARDINALITY,
					0 AS PAGES,
					'' AS FILTER_CONDITION
				FROM pragma_table_info('#arguments.table#')
				WHERE pk > 0

				ORDER BY INDEX_NAME, ORDINAL_POSITION;
			";
			local.rv = $query(sql = local.sql, datasource = arguments.datasource);
			return local.rv;
		}

		// If the cfdbinfo call fails we try it again, this time setting "dbname" explicitly.
		// Sometimes the call fails when using a custom database connection string.
		// In that case the database name is not known by the CF server and it will just use any of the databases that the data source has access to.
		// That can incorrectly be "information_schema" for example.
		try {
			local.args = {};
			for (local.key in arguments) {
				local.args[local.key] = arguments[local.key];
			}
			cfdbinfo(attributeCollection = local.args);
		} catch (any e) {
			local.args = {};
			for (local.key in arguments) {
				local.args[local.key] = arguments[local.key];
			}
			cfdbinfo(attributeCollection = local.args);
			local.type = arguments.type;
			arguments.type = "dbnames";
			local.args = {};
			for (local.key in arguments) {
				local.args[local.key] = arguments[local.key];
			}
			cfdbinfo(attributeCollection = local.args);
			if (local.rv.recordCount GT 1) {
				for (local.i in local.rv) {
					if (local.i.database_name IS NOT "information_schema") {
						arguments.dbname = local.i.database_name;
					}
				}
			}
			arguments.type = local.type;
			local.args = {};
			for (local.key in arguments) {
				local.args[local.key] = arguments[local.key];
			}
			cfdbinfo(attributeCollection = local.args);
		}

		// Override name for test mode
		if (
			arguments.type IS "version" AND
			StructKeyExists(url, "controller") AND
			StructKeyExists(url, "action") AND
			StructKeyExists(url, "view") AND
			StructKeyExists(url, "type") AND
			StructKeyExists(url, "adapter")
		) {
			if (url.controller IS "wheels" AND url.action IS "wheels" AND url.view IS "tests" AND url.type IS "core") {
				QuerySetCell(local.rv, "driver_name", url.adapter);
			}
		}

		return local.rv;
	}


	/**
	 * Drops rows belonging to a database's system schemas from a `$dbinfo(type="columns")`
	 * result.
	 *
	 * `cfdbinfo(type="columns")` passes no schema restriction to JDBC's `getColumns()`, so the
	 * table name is matched across EVERY schema on the connection. PostgreSQL and YugabyteDB
	 * ship real ANSI `information_schema` views named `sequences`, `tables`, `columns`,
	 * `views`, `triggers` and more, so an application table sharing one of those names silently
	 * collects a second batch of phantom columns from the catalog (issue #3349). No application
	 * table lives in a system schema, so filtering them out is always safe.
	 *
	 * A result set that carries no `table_schem` column — several engines omit it — is returned
	 * untouched. Yes, JDBC really does spell it `table_schem`, not `table_schema`.
	 */
	public query function $excludeSystemSchemaRows(
		required query columns,
		string schemas = "information_schema,pg_catalog,crdb_internal,pg_extension"
	) {
		if (!ListFindNoCase(arguments.columns.columnList, "table_schem")) {
			return arguments.columns;
		}
		local.rv = QueryNew(arguments.columns.columnList);
		local.columnNames = ListToArray(arguments.columns.columnList);
		local.iEnd = arguments.columns.recordCount;
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (!ListFindNoCase(arguments.schemas, arguments.columns["table_schem"][local.i])) {
				QueryAddRow(local.rv);
				local.jEnd = ArrayLen(local.columnNames);
				for (local.j = 1; local.j <= local.jEnd; local.j++) {
					local.item = local.columnNames[local.j];
					QuerySetCell(local.rv, local.item, arguments.columns[local.item][local.i]);
				}
			}
		}
		return local.rv;
	}


	public any function $wddx(required any input, string action = "cfml2wddx", boolean useTimeZoneInfo = true) {
		arguments.output = "local.output";
		local.args = {};
		for (local.key in arguments) {
			local.args[local.key] = arguments[local.key];
		}
		cfwddx(attributeCollection = "#local.args#");
		if (StructKeyExists(local, "output")) {
			return local.output;
		}
	}


	public any function $zip() {
		$engineAdapter().prepareZipArgs(arguments);
		local.action = StructKeyExists(arguments, "action") ? LCase(arguments.action) : "";
		if (
			local.action == "unzip"
			&& StructKeyExists(arguments, "file")
			&& StructKeyExists(arguments, "destination")
		) {
			$assertZipEntriesContained(arguments.file, arguments.destination);
		}
		local.args = {};
		for (local.key in arguments) {
			local.args[local.key] = arguments[local.key];
		}
		cfzip(attributeCollection = "#local.args#");
	}

	/**
	 * Returns true when a zip entry would extract outside destination.
	 * Rejects empty names, absolute paths, `..` segments, and any entry
	 * whose canonical path is not contained by the destination directory.
	 */
	public boolean function $zipEntryEscapesDestination(required string destination, required string entryName) {
		local.entry = Replace(arguments.entryName, "\", "/", "all");
		if (!Len(Trim(local.entry))) {
			return true;
		}
		if (Left(local.entry, 1) == "/" || REFind("^[A-Za-z]:", local.entry)) {
			return true;
		}
		local.segments = ListToArray(local.entry, "/");
		for (local.seg in local.segments) {
			if (local.seg == "..") {
				return true;
			}
		}
		try {
			local.destFile = CreateObject("java", "java.io.File").init(arguments.destination);
			local.destCanon = local.destFile.getCanonicalPath();
			local.sep = CreateObject("java", "java.io.File").separator;
			local.destPrefix = local.destCanon;
			if (Right(local.destPrefix, 1) != local.sep) {
				local.destPrefix = local.destPrefix & local.sep;
			}
			local.target = CreateObject("java", "java.io.File").init(local.destFile, local.entry);
			local.targetCanon = local.target.getCanonicalPath();
			if (local.targetCanon == local.destCanon) {
				return false;
			}
			return CompareNoCase(Left(local.targetCanon, Len(local.destPrefix)), local.destPrefix) != 0;
		} catch (any e) {
			return true;
		}
	}

	/**
	 * Lists entry names in a zip via java.util.zip.ZipFile so every engine
	 * sees the same names before cfzip writes anything.
	 */
	public array function $zipEntryNames(required string zipFile) {
		local.names = [];
		local.zf = CreateObject("java", "java.util.zip.ZipFile").init(arguments.zipFile);
		try {
			local.entries = local.zf.entries();
			while (local.entries.hasMoreElements()) {
				local.entry = local.entries.nextElement();
				ArrayAppend(local.names, local.entry.getName());
			}
		} finally {
			local.zf.close();
		}
		return local.names;
	}

	/**
	 * Throws Wheels.UnsafeZipEntry when any entry would escape destination.
	 */
	public void function $assertZipEntriesContained(required string zipFile, required string destination) {
		local.names = $zipEntryNames(arguments.zipFile);
		for (local.entry in local.names) {
			if ($zipEntryEscapesDestination(arguments.destination, local.entry)) {
				Throw(
					type = "Wheels.UnsafeZipEntry",
					message = "Zip entry '#local.entry#' escapes destination '#arguments.destination#'"
				);
			}
		}
	}


	public any function $query(required string sql) {
		StructDelete(arguments, "name");
		// allow the use of query of queries, caveat: Query must be called query. Eg: SELECT * from query
		if (StructKeyExists(arguments, "query") && IsQuery(arguments.query)) {
			var query = Duplicate(arguments.query);
		}
		local.rv = QueryExecute(PreserveSingleQuotes(arguments.sql), [], arguments);
		// some sql statements may not return a value
		if (StructKeyExists(local, "rv")) {
			return local.rv;
		}
	}
</cfscript>
