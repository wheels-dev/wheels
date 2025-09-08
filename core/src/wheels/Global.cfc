component output="false" {

	public any function $doubleCheckedLock(required string name, required string condition, required string execute, struct conditionArgs = "#StructNew()#", struct executeArgs = "#StructNew()#", numeric timeout=30){
		local.rv = $invoke(method = arguments.condition, invokeArgs = arguments.conditionArgs);
		if(IsBoolean(local.rv) AND NOT local.rv){
			lock timeout="#arguments.timeout#" name="#arguments.name#" {
				local.rv = $invoke(method = arguments.condition, invokeArgs = arguments.conditionArgs);
				if(IsBoolean(local.rv) AND NOT local.rv){
					local.rv = $invoke(method = arguments.execute, invokeArgs = arguments.executeArgs)
				}
			}
		}
		return local.rv;
	}

	public any function $simpleLock(required string name, required string type, required string execute, struct executeArgs = "#StructNew()#", numeric timeout=30){
		if(StructKeyExists(arguments, "object")){
			lock name="#arguments.name#" type="#arguments.type#" timeout="#arguments.timeout#" {
				local.rv = $invoke(component = "#arguments.object#", method = "#arguments.execute#", argumentCollection = "#arguments.executeArgs#");
			}
		}else{
			arguments.executeArgs.$locked = true;
			lock name="#arguments.name#" type="#arguments.type#" timeout="#arguments.timeout#"{
				local.rv = $invoke(method = "#arguments.execute#", argumentCollection = "#arguments.executeArgs#");
			}
		}
		if(StructKeyExists(local, "rv")){
			return local.rv;
		}
	}

	public struct function $image(){
    	local.rv = {};
		if (structKeyExists(server, "boxlang")) {
			if (arguments.action == "info") {
				var img = ImageRead(arguments.source);
				local.rv = ImageInfo(img);
			} else {
				throw(
					type = "Wheels.Image.UnsupportedAction",
					message = "The `$image()` function in BoxLang currently supports only the 'info' action."
				);
			}
		} else {
			// Adobe or Lucee: use cfimage
			arguments.structName = "rv";
			cfimage(attributeCollection = arguments);
			local.rv = local.rv;
		}
		return local.rv;
	}

	public void function $mail(){
    if(StructKeyExists(arguments, "mailparts")){
        local.mailparts = arguments.mailparts;
        StructDelete(arguments, "mailparts");
    }
    if(StructKeyExists(arguments, "mailparams")){
        local.mailparams = arguments.mailparams;
		StructDelete(arguments, "mailparams");
    }
    if(StructKeyExists(arguments, "tagContent")){
        local.tagContent = arguments.tagContent;
		StructDelete(arguments, "tagContent");
    }
    cfmail(attributeCollection="#arguments#"){
      if(StructKeyExists(local, "mailparams")){
        for(local.i in local.mailparams){
            cfmailparam(attributeCollection="#local.i#");
        }
      }
      if(StructKeyExists(local, "mailparts")){
        for(local.i in local.mailparts){
          local.innerTagContent = local.i.tagContent;
			    StructDelete(local.i, "tagContent");
          cfmailpart(attributeCollection="#local.i#"){
            writeOutput(local.innerTagContent)
					}
        }
      }
      if(StructKeyExists(local, "tagContent")){
        writeOutput(local.tagContent)
      }
    }
	}

	public any function $cache(){
    // If cache is found only the function is aborted, not page. --->
		variables.$instance.reCache = false;
		cfcache(attributeCollection="#arguments#");
		variables.$instance.reCache = true;
	}

	public any function $content(){
    cfcontent(attributeCollection="#arguments#");
	}

	public void function $header(){
    cfheader(attributeCollection="#arguments#");
	}

	public void function $include(required string template){
    include "#LCase(arguments.template)#";
	}

	public void function $includeAndOutput(required string template){
    include "#LCase(arguments.template)#";
	}

	public string function $includeAndReturnOutput(required string $template){
    // Make it so the developer can reference passed in arguments in the loc scope if they prefer.
		if(StructKeyExists(arguments, "$type") AND arguments.$type IS "partial"){
			local = arguments;
  	}
		// Include the template and return the result.
		// Variable is set to $wheels to limit chances of it being overwritten in the included template.
		// cfformat-ignore-start
  	savecontent variable="local.$wheels" {
  	  include "#LCase(arguments.$template)#"
  	};
		// cfformat-ignore-end
		return local.$wheels;
	}

	public any function $directory(){
    local.rv = "";
    arguments.name = "rv";
		cfdirectory(attributeCollection="#arguments#");
		return local.rv;
	}

	public any function $file(){
    cffile(attributeCollection="#arguments#");
	}

	public any function $cfinvoke(required string component, required string method, struct invokeArguments){
    cfinvoke
        component="#arguments.component#"
        method="#arguments.method#"
        returnVariable="#arguments.returnVariable#"
        argumentCollection="#arguments.invokeArguments#";
    return local.rv;
	}

	public any function $invoke(){
    arguments.returnVariable = "local.rv";
    if(StructKeyExists(arguments, "componentReference")){
      arguments.component = arguments.componentReference;
      StructDelete(arguments, "componentReference");
    }else if(NOT StructKeyExists(variables, arguments.method)){
      // this is done so that we can call dynamic methods via "onMissingMethod" on the object (we need to pass in the object for this so it can call methods on the "this" scope instead)
      arguments.component = this;
    }
    if(StructKeyExists(arguments, "invokeArgs")){
      arguments.argumentCollection = arguments.invokeArgs;
      if(StructCount(arguments.argumentCollection) IS NOT ListLen(StructKeyList(arguments.argumentCollection))){
        // work-around for fasthashremoved cf8 bug
        arguments.argumentCollection = StructNew();
        for(local.i in StructKeyList(arguments.invokeArgs)){
          arguments.argumentCollection[local.i] = arguments.invokeArgs[local.i];
        }
      }


      if(StructKeyExists(arguments.invokeArgs, "componentReference")){
      	arguments.component = arguments.invokeArgs.componentReference;
      }


      StructDelete(arguments, "invokeArgs");
    }
    cfinvoke(attributeCollection="#arguments#");
    if(StructKeyExists(local, "rv")){
      return local.rv;
    }
	}

	public void function $location(boolean delay = false){
    StructDelete(arguments, "$args", false);
    if(NOT arguments.delay){
      StructDelete(arguments, "delay", false);
      cflocation(attributeCollection="#arguments#");
    }
	}

	public void function $htmlhead(){
    cfhtmlhead(attributeCollection="#arguments#");
	}

	public any function $dbinfo(){
    arguments.name = "local.rv";
    if(StructKeyExists(arguments, "username") && !Len(arguments.username)){
      StructDelete(arguments, "username");
    }
    if(StructKeyExists(arguments, "password") && !Len(arguments.password)){
      StructDelete(arguments, "password");
    }

	// BoxLang + SQL Server specific fix for index queries to avoid casting error
    if (StructKeyExists(server, "boxlang") && 
        StructKeyExists(arguments, "type") && arguments.type == "index" &&
        StructKeyExists(arguments, "table")) {
      
		// Get database adapter to check if it's SQL Server
		local.adapter = $get("adapterName");
		if (local.adapter == "SQLServer") {
			// Use direct SQL query instead of cfdbinfo for BoxLang + SQL Server index queries
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
			
			local.rv = $query(sql=local.sql, datasource=arguments.datasource);
			return local.rv;
		}
		
		// Get database adapter to check if it's Oracle
		if (local.adapter == "Oracle") {
			// Use direct SQL query instead of cfdbinfo for BoxLang + Oracle index queries
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
			
			local.rv = $query(sql=local.sql, datasource=arguments.datasource);
			return local.rv;
		}
    }

    // If the cfdbinfo call fails we try it again, this time setting "dbname" explicitly.
		// Sometimes the call fails when using a custom database connection string.
		// In that case the database name is not known by the CF server and it will just use any of the databases that the data source has access to.
		// That can incorrectly be "information_schema" for example.
    try{
      cfdbinfo(attributeCollection="#arguments#");
    }catch(any e){
      cfdbinfo(attributeCollection="#arguments#");
      local.type = arguments.type;
			arguments.type = "dbnames";
      cfdbinfo(attributeCollection="#arguments#");
      if(local.rv.recordCount GT 1){
        for(local.i in local.rv){
          if(local.i.database_name IS NOT "information_schema"){
            arguments.dbname = local.i.database_name;
          }
        }
      }
      arguments.type = local.type;
      cfdbinfo(attributeCollection="#arguments#");
    }

    // Override name of database adapter when running internal tests
    if(arguments.type IS "version"
       AND StructKeyExists(url, "controller")
       AND StructKeyExists(url, "action")
       AND StructKeyExists(url, "view")
       AND StructKeyExists(url, "type")
       AND StructKeyExists(url, "adapter")){
      if(url.controller IS "wheels" AND url.action IS "wheels" AND url.view IS "tests" AND url.type IS "core"){
        QuerySetCell(local.rv, "driver_name", url.adapter);
      }
    }

    return local.rv;
	}

	public any function $wddx(required any input, string action = "cfml2wddx", boolean useTimeZoneInfo = true){
    arguments.output = "local.output";
    cfwddx(attributeCollection="#arguments#");
    if(StructKeyExists(local, "output")){
      return local.output;
    }
	}

	public any function $zip(){
		if (structKeyExists(server, "boxlang")) {
			if (!left(arguments.file, 1) == "/") {
				arguments.file = "/" & arguments.file;
			}
			if (!left(arguments.destination, 1) == "/") {
				arguments.destination = "/" & arguments.destination;
			}
		}
 		cfzip(attributeCollection="#arguments#");
	}

	public any function $query(required string sql){
    StructDelete(arguments, "name");
    // allow the use of query of queries, caveat: Query must be called query. Eg: SELECT * from query
		if(StructKeyExists(arguments, "query") && IsQuery(arguments.query)){
			var query = Duplicate(arguments.query);
    }

    local.rv = queryExecute(PreserveSingleQuotes(arguments.sql), [],  arguments);
		// some sql statements may not return a value
		if(StructKeyExists(local, "rv")){
			return local.rv;
    }
	}


	/**
	 * Call CFML's canonicalize() function but set to blank string if the result is null (happens on Lucee 5).
	 */
	public string function $canonicalize(required string input) {
		local.rv = Canonicalize(arguments.input, false, false);
		if (IsNull(local.rv)) {
			local.rv = "";
		}
		return local.rv;
	}

	/**
	 * Get the status code (e.g. 200, 404 etc) of the response we're about to send.
	 */
	public string function $statusCode() {
		if (StructKeyExists(server, "lucee")) {
			local.response = GetPageContext().getResponse();
		} else {
			local.response = GetPageContext().getFusionContext().getResponse();
		}
		return local.response.getStatus();
	}

	/**
	 * Gets the value of the content type header (blank string if it doesn't exist) of the response we're about to send.
	 */
	public string function $contentType() {
		local.rv = "";
		local.pageContext = getPageContext();
		if (structKeyExists(server, "boxlang")) {
			local.response = local.pageContext;
		} else if (structKeyExists(server, "lucee")) {
			local.response = local.pageContext.getResponse();
		} else {
			local.response = local.pageContext.getFusionContext().getResponse();
		}

		if (structKeyExists(server, "boxlang")) {
			local.headerMap = local.response.getResponseHeaderMap();
			if (structKeyExists(local.headerMap, "Content-Type")) {
				local.headerArray = local.headerMap["Content-Type"];
				if (arrayLen(local.headerArray) > 0 && !isNull(local.headerArray[1])) {
					local.rv = local.headerArray[1];
				}
			}
		} else {
			if (local.response.containsHeader("Content-Type")) {
				local.header = local.response.getHeader("Content-Type");
				if (!isNull(local.header)) {
					local.rv = local.header;
				}
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $initializeRequestScope() {
		if (!StructKeyExists(request, "wheels")) {
			request.wheels = {};
			request.wheels.params = {};
			request.wheels.cache = {};
			request.wheels.urlForCache = {};
			request.wheels.tickCountId = GetTickCount();

			// Copy HTTP request data (contains content, headers, method and protocol).
			// This makes internal testing easier since we can overwrite it temporarily from the test suite.
			request.wheels.httpRequestData = GetHTTPRequestData();

			// Create a structure to track the transaction status for all adapters.
			request.wheels.transactions = {};
		}
	}

	/**
	 * Internal function.
	 */
	public xml function $toXml(required any data) {
		// only instantiate the toXml object once per request
		if (!StructKeyExists(request.wheels, "toXml")) {
			request.wheels.toXml = $createObjectFromRoot(
				path = "#application.wheels.wheelsComponentPath#.vendor.toXml",
				fileName = "toXML",
				method = "init"
			);
		}

		/* Wirebox adjustment */
		if (isStruct(arguments.data) && StructKeyExists(arguments.data, '$wbMixer')){
			structDelete(arguments.data, '$wbMixer');
		}

		return request.wheels.toXml.toXml(arguments.data);
	}

	/**
	 * Internal function.
	 */
	public string function $convertToString(required any value, string type = "") {
		// BoxLang compatibility: Pre-process problematic date strings before type detection
		if (StructKeyExists(server, "boxlang") && IsSimpleValue(arguments.value) && ReFindNoCase("^\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2} (AM|PM)$", arguments.value)) {
			// Manually parse DD/MM/YYYY format to avoid BoxLang's MM/DD/YYYY interpretation
			local.parts = ListToArray(arguments.value, " ");
			local.datePart = local.parts[1];
			local.timePart = local.parts[2];
			local.amPm = local.parts[3];
			
			local.dateComponents = ListToArray(local.datePart, "/");
			local.timeComponents = ListToArray(local.timePart, ":");
			
			local.day = Val(local.dateComponents[1]);    // First = day (DD/MM/YYYY)
			local.month = Val(local.dateComponents[2]);  // Second = month
			local.year = Val(local.dateComponents[3]);
			local.hour = Val(local.timeComponents[1]);
			local.minute = Val(local.timeComponents[2]);
			
			if (local.amPm == "PM" && local.hour != 12) {
				local.hour += 12;
			} else if (local.amPm == "AM" && local.hour == 12) {
				local.hour = 0;
			}
			arguments.value = CreateDateTime(local.year, local.month, local.day, local.hour, local.minute, 0);
		}

		if (!Len(arguments.type)) {
			if (IsArray(arguments.value)) {
				arguments.type = "array";
			} else if (IsStruct(arguments.value)) {
				arguments.type = "struct";
			} else if (IsBinary(arguments.value)) {
				arguments.type = "binary";
			} else if (IsNumeric(arguments.value)) {
				arguments.type = "integer";
			} else if (IsDate(arguments.value)) {
				arguments.type = "datetime";
			}
		}
		switch (arguments.type) {
			case "array":
				arguments.value = ArrayToList(arguments.value);
				break;
			case "struct":
				local.str = "";
				local.keyList = ListSort(StructKeyList(arguments.value), "textnocase", "asc");
				local.iEnd = ListLen(local.keyList);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.key = ListGetAt(local.keyList, local.i);
					local.str = ListAppend(local.str, local.key & "=" & arguments.value[local.key]);
				}
				arguments.value = local.str;
				break;
			case "binary":
				arguments.value = ToString(arguments.value);
				break;
			case "float":
			case "integer":
				if (!Len(arguments.value)) {
					return "";
				}
				if (arguments.value == "true") {
					return 1;
				}
				arguments.value = Val(arguments.value);
				break;
			case "boolean":
				if (Len(arguments.value)) {
					arguments.value = (arguments.value IS true);
				}
				break;
			case "datetime":
				if(isInstanceOf(arguments.value, "oracle.sql.TIMESTAMP")){
					arguments.value = arguments.value.timestampValue();
				}
				// createdatetime will throw an error
				if (IsDate(arguments.value)) {
					arguments.value = CreateDateTime(
						Year(arguments.value),
						Month(arguments.value),
						Day(arguments.value),
						Hour(arguments.value),
						Minute(arguments.value),
						Second(arguments.value)
					);
				}
				break;
		}
		return arguments.value;
	}

	/**
	 * Internal function.
	 */
	public any function $cleanInlist(required string where) {
		local.rv = arguments.where;
		local.regex = "IN\s?\(.*?,?\s?.*?\)";
		local.in = ReFind(local.regex, local.rv, 1, true);
		while (local.in.len[1]) {
			local.str = Mid(local.rv, local.in.pos[1], local.in.len[1]);
			local.rv = RemoveChars(local.rv, local.in.pos[1], local.in.len[1]);
			local.cleaned = $listClean(local.str);
			local.rv = Insert(local.cleaned, local.rv, local.in.pos[1] - 1);
			local.in = ReFind(local.regex, local.rv, local.in.pos[1] + Len(local.cleaned), true);
		}
		return local.rv;
	}

	/**
	 * Removes whitespace between list elements.
	 * Optional argument to return the list as an array.
	 */
	public any function $listClean(required string list, string delim = ",", string returnAs = "string") {
		local.rv = ListToArray(arguments.list, arguments.delim);
		local.iEnd = ArrayLen(local.rv);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.rv[local.i] = Trim(local.rv[local.i]);
		}
		if (arguments.returnAs != "array") {
			local.rv = ArrayToList(local.rv, arguments.delim);
		}
		return local.rv;
	}

	/**
	 * Converts a comma delimted list to a struct
	 */
	public struct function $listToStruct(required string list, string value = 1) {
		local.rv = {};
		local.cleanList = $listClean(list = arguments.list, returnAs = "array");
		for (local.key in local.cleanList) {
			local.rv[local.key] = arguments.value;
		}
		return local.rv;
	}

	/**
	 * Creates a unique string based on any arguments passed in (used as a key for caching mostly).
	 */
	public string function $hashedKey() {
		local.rv = "";

		// make all cache keys domain specific (do not use request scope below since it may not always be initialized)
		StructInsert(arguments, ListLen(StructKeyList(arguments)) + 1, cgi.http_host, true);

		// we need to make sure we are looping through the passed in arguments in the same order everytime
		local.values = [];
		local.keyList = ListSort(StructKeyList(arguments), "textnocase", "asc");
		local.iEnd = ListLen(local.keyList);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			ArrayAppend(local.values, arguments[ListGetAt(local.keyList, local.i)]);
		}

		if (!ArrayIsEmpty(local.values)) {
			// this might fail if a query contains binary data so in those rare cases we fall back on using cfwddx (which is a little bit slower which is why we don't use it all the time)
			try {
				local.rv = SerializeJSON(local.values);
				// BoxLang compatibility: For consistent hashing, normalize array representations
				if (structKeyExists(server, "boxlang")) {
					// Convert to a more predictable format by removing structural chars and sorting
					local.normalized = REReplace(local.rv, '[\[\]{}"]', "", "all");
					local.parts = listToArray(local.normalized, ",");
					arraySort(local.parts, "textnocase");
					local.rv = arrayToList(local.parts, ",");
				} else {
					// remove the characters that indicate array or struct so that we can sort it as a list below
					local.rv = ReplaceList(local.rv, "{,},[,],/", ",,,,");
					local.rv = ListSort(local.rv, "text");
				}
			} catch (any e) {
				local.rv = $wddx(input = local.values);
			}
		}
		return Hash(local.rv);
	}

	/**
	 * Internal function.
	 */
	public any function $timeSpanForCache(
		required any cache,
		numeric defaultCacheTime = application.wheels.defaultCacheTime,
		string cacheDatePart = application.wheels.cacheDatePart
	) {
		local.cache = arguments.defaultCacheTime;
		if (IsNumeric(arguments.cache)) {
			local.cache = arguments.cache;
		}
		local.list = "0,0,0,0";
		local.dateParts = "d,h,n,s";
		local.iEnd = ListLen(local.dateParts);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (arguments.cacheDatePart == ListGetAt(local.dateParts, local.i)) {
				local.list = ListSetAt(local.list, local.i, local.cache);
			}
		}
		local.rv = CreateTimespan(
			ListGetAt(local.list, 1),
			ListGetAt(local.list, 2),
			ListGetAt(local.list, 3),
			ListGetAt(local.list, 4)
		);
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $timestamp(string timeStampMode = application.wheels.timeStampMode) {
		switch (arguments.timeStampMode) {
			case "utc":
				local.rv = DateConvert("local2Utc", Now());
				break;
			case "local":
				local.rv = Now();
				break;
			case "epoch":
				local.rv = Now().getTime();
				break;
			default:
				Throw(type = "Wheels.InvalidTimeStampMode", message = "Timestamp mode #arguments.timeStampMode# is invalid");
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $combineArguments(
		required struct args,
		required string combine,
		required boolean required = false,
		string extendedInfo = ""
	) {
		local.first = ListGetAt(arguments.combine, 1);
		local.second = ListGetAt(arguments.combine, 2);
		if (StructKeyExists(arguments.args, local.second)) {
			arguments.args[local.first] = arguments.args[local.second];
			StructDelete(arguments.args, local.second);
		}
		if (arguments.required && application.wheels.showErrorInformation) {
			if (!StructKeyExists(arguments.args, local.first) || !Len(arguments.args[local.first])) {
				Throw(
					type = "Wheels.IncorrectArguments",
					message = "The `#local.second#` or `#local.first#` argument is required but was not passed in.",
					extendedInfo = "#arguments.extendedInfo#"
				);
			}
		}
	}


	/**
	 * Check to see if all keys in the list exist for the structure and have length.
	 */
	public boolean function $structKeysExist(required struct struct, string keys = "") {
		local.rv = true;
		local.iEnd = ListLen(arguments.keys);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			if (
				!StructKeyExists(arguments.struct, ListGetAt(arguments.keys, local.i))
				|| (
					IsSimpleValue(arguments.struct[ListGetAt(arguments.keys, local.i)])
					&& !Len(arguments.struct[ListGetAt(arguments.keys, local.i)])
				)
			) {
				local.rv = false;
				break;
			}
		}
		return local.rv;
	}

	/**
	 * This copies all the variables Wheels needs from the CGI scope to the request scope.
	 */
	public struct function $cgiScope(
		string keys = "request_method,http_x_requested_with,http_referer,server_name,path_info,script_name,query_string,remote_addr,server_port,server_port_secure,server_protocol,http_host,http_accept,content_type,http_x_rewrite_url,http_x_original_url,request_uri,redirect_url,http_x_forwarded_for,http_x_forwarded_proto",
		struct scope = cgi
	) {
		local.rv = {};
		local.iEnd = ListLen(arguments.keys);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.keys, local.i);
			local.rv[local.item] = arguments.scope[local.item];
		}

		// fix path_info if it contains any characters that are not ascii (see issue 138)
		if (StructKeyExists(arguments.scope, "unencoded_url") && Len(arguments.scope.unencoded_url)) {
			local.requestUrl = UrlDecode(arguments.scope.unencoded_url);
		} else if (IsSimpleValue(GetPageContext().getRequest().getRequestURL())) {
			// remove protocol, domain, port etc from the url
			local.requestUrl = "/" & ListDeleteAt(
				ListDeleteAt(UrlDecode(GetPageContext().getRequest().getRequestURL()), 1, "/"),
				1,
				"/"
			);
		}
		if (StructKeyExists(local, "requestUrl") && ReFind("[^\x00-\x80]", local.requestUrl)) {
			// strip out the script_name and query_string leaving us with only the part of the string that should go in path_info
			local.rv.path_info = Replace(
				Replace(local.requestUrl, arguments.scope.script_name, ""),
				"?" & UrlDecode(arguments.scope.query_string),
				""
			);
		}

		// fixes IIS issue that returns a blank cgi.path_info
		if (!Len(local.rv.path_info) && Right(local.rv.script_name, 10) == "/index.cfm") {
			if (Len(local.rv.http_x_rewrite_url)) {
				// IIS6 1/ IIRF (Ionics Isapi Rewrite Filter)
				local.rv.path_info = ListFirst(local.rv.http_x_rewrite_url, "?");
			} else if (Len(local.rv.http_x_original_url)) {
				// IIS7 rewrite default
				local.rv.path_info = ListFirst(local.rv.http_x_original_url, "?");
			} else if (Len(local.rv.request_uri)) {
				// Apache default
				local.rv.path_info = ListFirst(local.rv.request_uri, "?");
			} else if (Len(local.rv.redirect_url)) {
				// Apache fallback
				local.rv.path_info = ListFirst(local.rv.redirect_url, "?");
			}

			// finally lets remove the index.cfm because some of the custom cgi variables don't bring it back
			// like this it means at the root we are working with / instead of /index.cfm
			if (Len(local.rv.path_info) >= 10 && Right(local.rv.path_info, 10) == "/index.cfm") {
				// this will remove the index.cfm and the trailing slash
				local.rv.path_info = Replace(local.rv.path_info, "/index.cfm", "");
				if (!Len(local.rv.path_info)) {
					// add back the forward slash if path_info was "/index.cfm"
					local.rv.path_info = "/";
				}
			}
		}

		// some web servers incorrectly place index.cfm in the path_info but since that should never be there we can safely remove it
		if (Find("index.cfm/", local.rv.path_info)) {
			Replace(local.rv.path_info, "index.cfm/", "");
		}
		return local.rv;
	}

	/**
	 * Creates a struct of the named arguments passed in to a function (i.e. the ones not explicitly defined in the arguments list).
	 *
	 * @defined List of already defined arguments that should not be added.
	 */
	public struct function $namedArguments(required string $defined) {
		local.rv = {};
		for (local.key in arguments) {
			if (!ListFindNoCase(arguments.$defined, local.key) && Left(local.key, 1) != "$") {
				local.rv[local.key] = arguments[local.key];
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public struct function $dollarify(required struct input, required string on) {
		for (local.key in arguments.input) {
			if (ListFindNoCase(arguments.on, local.key)) {
				arguments.input["$" & local.key] = arguments.input[local.key];
				StructDelete(arguments.input, local.key);
			}
		}
		return arguments.input;
	}

	/**
	 * Internal function.
	 */
	public void function $abortInvalidRequest() {
		local.applicationPath = Replace(GetCurrentTemplatePath(), "\", "/", "all");
		local.callingPath = Replace(GetBaseTemplatePath(), "\", "/", "all");
		if (
			!(GetFileFromPath(local.callingPath) == "runner.cfm")
			&&
			ListLen(local.callingPath, "/") > ListLen(local.applicationPath, "/")
		) {
			if (StructKeyExists(application, "wheels")) {
				if (StructKeyExists(application.wheels, "showErrorInformation") && !application.wheels.showErrorInformation) {
					$header(statusCode = 404, statustext = "Not Found");
				}
				if (StructKeyExists(application.wheels, "eventPath")) {
					$includeAndOutput(template = "#application.wheels.eventPath#/onmissingtemplate.cfm");
				}
			}
			$header(statusCode = 404, statustext = "Not Found");
			abort;
		}
	}

	/**
	 * Internal function.
	 */
	public string function $routeVariables() {
		return $findRoute(argumentCollection = arguments).foundvariables;
	}

	/**
	 * Internal function.
	 */
	public struct function $findRoute() {
		// Throw error if no route was found.
		if (!StructKeyExists(application.wheels.namedRoutePositions, arguments.route)) {
			$throwErrorOrShow404Page(
				type = "Wheels.RouteNotFound",
				message = "Could not find the `#arguments.route#` route.",
				extendedInfo = "Make sure there is a route configured in your `config/routes.cfm` file named `#arguments.route#`."
			);
		}
		local.routePos = application.wheels.namedRoutePositions[arguments.route];
		if (Find(",", local.routePos)) {
			// there are several routes with this name so we need to figure out which one to use by checking the passed in arguments
			local.iEnd = ListLen(local.routePos);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.rv = application.wheels.routes[ListGetAt(local.routePos, local.i)];
				local.foundRoute = StructKeyExists(arguments, "method") && local.rv.methods == arguments.method;
				local.jEnd = ListLen(local.rv.foundvariables);
				for (local.j = 1; local.j <= local.jEnd; local.j++) {
					local.variable = ListGetAt(local.rv.foundvariables, local.j);
					if (!StructKeyExists(arguments, local.variable) || !Len(arguments[local.variable])) {
						local.foundRoute = false;
					}
				}
				if (local.foundRoute) {
					break;
				}
			}
		} else {
			local.rv = application.wheels.routes[local.routePos];
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public any function $cachedModelClassExists(required string name) {
		local.rv = false;
		if (StructKeyExists(application.wheels.models, arguments.name)) {
			local.rv = application.wheels.models[arguments.name];
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $constructParams(
		required string params,
		boolean encode = true,
		boolean $encodeForHtmlAttribute = false,
		string $URLRewriting = application.wheels.URLRewriting
	) {
		// When rewriting is off we will already have "?controller=" etc in the url so we have to continue with an ampersand.
		if (arguments.$URLRewriting == "Off") {
			local.delim = "&";
		} else {
			local.delim = "?";
		}

		local.rv = "";
		local.iEnd = ListLen(arguments.params, "&");
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.params = ListToArray(ListGetAt(arguments.params, local.i, "&"), "=");
			local.name = local.params[1];
			if (arguments.encode && $get("encodeURLs")) {
				local.name = EncodeForURL($canonicalize(local.name));
				if (arguments.$encodeForHtmlAttribute) {
					local.name = EncodeForHTMLAttribute(local.name);
				}
			}
			local.rv &= local.delim & local.name & "=";
			local.delim = "&";
			if (ArrayLen(local.params) == 2) {
				local.value = local.params[2];
				if (arguments.encode && $get("encodeURLs")) {
					local.value = EncodeForURL($canonicalize(local.value));
					if (arguments.$encodeForHtmlAttribute) {
						local.value = EncodeForHTMLAttribute(local.value);
					}
				}

				// Obfuscate the param if set globally and we're not processing cfid or cftoken (can't touch those).
				// Wrap in double quotes because in Lucee we have to pass it in as a string otherwise leading zeros are stripped.
				if (application.wheels.obfuscateUrls && !ListFindNoCase("cfid,cftoken", local.name)) {
					local.value = obfuscateParam("#local.value#");
				}

				local.rv &= local.value;
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $args(
		required struct args,
		required string name,
		string reserved = "",
		string combine = "",
		string required = ""
	) {
		if (Len(arguments.combine)) {
			local.iEnd = ListLen(arguments.combine);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.item = ListGetAt(arguments.combine, local.i);
				local.first = ListGetAt(local.item, 1, "/");
				local.second = ListGetAt(local.item, 2, "/");
				local.required = false;
				if (ListLen(local.item, "/") > 2 || ListFindNoCase(local.first, arguments.required)) {
					local.required = true;
				}
				$combineArguments(args = arguments.args, combine = "#local.first#,#local.second#", required = local.required);
			}
		}
		if (application.wheels.showErrorInformation) {
			if (ListLen(arguments.reserved)) {
				local.iEnd = ListLen(arguments.reserved);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.item = ListGetAt(arguments.reserved, local.i);
					if (StructKeyExists(arguments.args, local.item)) {
						Throw(
							type = "Wheels.IncorrectArguments",
							message = "The `#local.item#` argument cannot be passed in since it will be set automatically by Wheels."
						);
					}
				}
			}
		}
		if (StructKeyExists(application.wheels.functions, arguments.name)) {
			if (structKeyExists(server, "boxlang")) {
				// Manual implementation for BoxLang
				for (local.key in application.wheels.functions[arguments.name]) {
					if (!StructKeyExists(arguments.args, local.key)) {
						arguments.args[local.key] = application.wheels.functions[arguments.name][local.key];
					}
				}
			} else {
				StructAppend(arguments.args, application.wheels.functions[arguments.name], false);
			}
		}

		// make sure that the arguments marked as required exist
		if (Len(arguments.required)) {
			local.iEnd = ListLen(arguments.required);
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.arg = ListGetAt(arguments.required, local.i);
				if (!StructKeyExists(arguments.args, local.arg)) {
					Throw(type = "Wheels.IncorrectArguments", message = "The `#local.arg#` argument is required but not passed in.");
				}
			}
		}
	}

	/**
	 * Internal function.
	 */
	public any function $createObjectFromRoot(required string path, required string fileName, required string method) {
		local.method = arguments.method;
		local.component = ListChangeDelims(arguments.path, ".", "/") & "." & ListChangeDelims(arguments.fileName, ".", "/");
		local.argumentCollection = arguments;
		if(local.method EQ 'init'){
			local.rv = application.wirebox.getInstance(name = "#local.component#", initArguments = local.argumentCollection);
		}
		else{
			local.instance = application.wirebox.getInstance(name = "#local.component#");
      local.rv = invoke(local.instance, local.method, local.argumentCollection);
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $debugPoint(required string name) {
		if (!StructKeyExists(request.wheels, "execution")) {
			request.wheels.execution = {};
		}
		local.iEnd = ListLen(arguments.name);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.item = ListGetAt(arguments.name, local.i);
			if (StructKeyExists(request.wheels.execution, local.item)) {
				request.wheels.execution[local.item] = GetTickCount() - request.wheels.execution[local.item];
			} else {
				request.wheels.execution[local.item] = GetTickCount();
			}
		}
	}

	/**
	 * Internal function.
	 */
	public any function $cachedControllerClassExists(required string name) {
		local.rv = false;
		if (StructKeyExists(application.wheels.controllers, arguments.name)) {
			local.rv = application.wheels.controllers[arguments.name];
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public any function $fileExistsNoCase(required string absolutePath) {
		local.appKey = $appKey();
		// return false by default when the file does not exist in the directory
		local.rv = false;
		// break up the full path string in the path name only and the file name only
		local.path = GetDirectoryFromPath(arguments.absolutePath);
		local.file = Replace(arguments.absolutePath, local.path, "");
		// get all existing files in the directory and place them in a list in application scope
		local.pathHash = Hash(local.path);
		if (!StructKeyExists(application[local.appKey].directoryFiles, local.pathHash)) {
			local.dirInfo = $directory(directory = local.path);
			application[local.appKey].directoryFiles[local.pathHash] = ValueList(local.dirInfo.name);
		}
		local.fileList = application[local.appKey].directoryFiles[local.pathHash];
		// loop through the file list and return the file name if exists regardless of case (the == operator is case insensitive)
		local.iEnd = ListLen(local.fileList);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.foundFile = ListGetAt(local.fileList, local.i);
			if (local.foundFile == local.file) {
				local.rv = local.foundFile;
				break;
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $objectFileName(required string name, required string objectPath, required string type) {
		// by default we return Model or Controller so that the base component gets loaded
		local.rv = capitalize(arguments.type);

		// we are going to store the full controller / model path in the
		// existing / non-existing lists so we can have controllers / models
		// in multiple places
		//
		// The name coming into $objectFileName could have dot notation due to
		// nested controllers so we need to change delims here on the name
		local.fullObjectPath = arguments.objectPath & "/" & ListChangeDelims(arguments.name, '/', '.');

		if (
			!ListFindNoCase(application.wheels.existingObjectFiles, local.fullObjectPath)
			&& !ListFindNoCase(application.wheels.nonExistingObjectFiles, local.fullObjectPath)
		) {
			// we have not yet checked if this file exists or not so let's do that
			// here (the function below will return the file name with the correct
			// case if it exists, false if not)
			local.file = $fileExistsNoCase(ExpandPath(local.fullObjectPath) & ".cfc");

			if (IsBoolean(local.file) && !local.file) {
				// no file exists, let's store that if caching is on so we don't have to check it again
				if (application.wheels.cacheFileChecking) {
					application.wheels.nonExistingObjectFiles = ListAppend(
						application.wheels.nonExistingObjectFiles,
						local.fullObjectPath
					);
				}
			} else {
				// the file exists, let's store the proper case of the file if caching is turned on
				local.file = SpanExcluding(local.file, ".");
				local.fullObjectPath = ListSetAt(local.fullObjectPath, ListLen(local.fullObjectPath, "/"), local.file, "/");
				if (application.wheels.cacheFileChecking) {
					application.wheels.existingObjectFiles = ListAppend(
						application.wheels.existingObjectFiles,
						local.fullObjectPath
					);
				}
			}
		}

		// if the file exists we return the file name in its proper case
		local.pos = ListFindNoCase(application.wheels.existingObjectFiles, local.fullObjectPath);
		if (local.pos) {
			local.file = ListLast(ListGetAt(application.wheels.existingObjectFiles, local.pos), "/");
		}

		// we've found a file so we'll need to send back the corrected name
		// argument as it could have dot notation in it from the mapper
		if (StructKeyExists(local, "file") and !IsBoolean(local.file)) {
			local.rv = ListSetAt(arguments.name, ListLen(arguments.name, "."), local.file, ".");
		}

		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public any function $createControllerClass(
		required string name,
		string controllerPaths = $get("controllerPath"),
		string type = "controller"
	) {
		// let's allow for multiple controller paths so that plugins can contain controllers
		// the last path is the one we will instantiate the base controller on if the controller is not found on any of the paths
		local.iEnd = ListLen(arguments.controllerPaths);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.controllerPath = ListGetAt(arguments.controllerPaths, local.i);
			local.fileName = $objectFileName(name = arguments.name, objectPath = local.controllerPath, type = arguments.type);
			if (local.fileName != "Controller" || local.i == ListLen(arguments.controllerPaths)) {
				application.wheels.controllers[arguments.name] = $createObjectFromRoot(
					path = local.controllerPath,
					fileName = local.fileName,
					method = "$initControllerClass",
					name = arguments.name
				);

				local.rv = application.wheels.controllers[arguments.name];
				break;
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $addToCache(
		required string key,
		required any value,
		numeric time = application.wheels.defaultCacheTime,
		string category = "main"
	) {
		if (
			application.wheels.cacheCullPercentage > 0
			&& application.wheels.cacheLastCulledAt < DateAdd("n", -application.wheels.cacheCullInterval, Now())
			&& $cacheCount() >= application.wheels.maximumItemsToCache
		) {
			// cache is full so flush out expired items from this cache to make more room if possible
			local.deletedItems = 0;
			local.cacheCount = $cacheCount();
			for (local.key in application.wheels.cache[arguments.category]) {
				if (Now() > application.wheels.cache[arguments.category][local.key].expiresAt) {
					$removeFromCache(key = local.key, category = arguments.category);
					if (application.wheels.cacheCullPercentage < 100) {
						local.deletedItems++;
						local.percentageDeleted = (local.deletedItems / local.cacheCount) * 100;
						if (local.percentageDeleted >= application.wheels.cacheCullPercentage) {
							break;
						}
					}
				}
			}
			application.wheels.cacheLastCulledAt = Now();
		}
		if ($cacheCount() < application.wheels.maximumItemsToCache) {
			local.cacheItem = {};
			local.cacheItem.expiresAt = DateAdd(application.wheels.cacheDatePart, arguments.time, Now());
			if (IsSimpleValue(arguments.value)) {
				local.cacheItem.value = arguments.value;
			} else {
				local.cacheItem.value = Duplicate(arguments.value);
			}
			application.wheels.cache[arguments.category][arguments.key] = local.cacheItem;
		}
	}

	/**
	 * Internal function.
	 */
	public any function $getFromCache(required string key, string category = "main") {
		local.rv = false;
		try {
			if (StructKeyExists(application.wheels.cache[arguments.category], arguments.key)) {
				if (Now() > application.wheels.cache[arguments.category][arguments.key].expiresAt) {
					$removeFromCache(key = arguments.key, category = arguments.category);
				} else {
					if (IsSimpleValue(application.wheels.cache[arguments.category][arguments.key].value)) {
						local.rv = application.wheels.cache[arguments.category][arguments.key].value;
					} else {
						local.rv = Duplicate(application.wheels.cache[arguments.category][arguments.key].value);
					}
				}
			}
		} catch (any e) {
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $removeFromCache(required string key, string category = "main") {
		StructDelete(application.wheels.cache[arguments.category], arguments.key);
	}

	/**
	 * Internal function.
	 */
	public numeric function $cacheCount(string category = "") {
		if (Len(arguments.category)) {
			local.rv = StructCount(application.wheels.cache[arguments.category]);
		} else {
			local.rv = 0;
			for (local.key in application.wheels.cache) {
				local.rv += StructCount(application.wheels.cache[local.key]);
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $clearCache(string category = "") {
		if (Len(arguments.category)) {
			StructClear(application.wheels.cache[arguments.category]);
		} else {
			StructClear(application.wheels.cache);
		}
	}

	/**
	 * Internal function.
	 */
	public any function $createModelClass(
		required string name,
		string modelPaths = application.wheels.modelPath,
		string type = "model"
	) {
		// let's allow for multiple model paths so that plugins can contain models
		// the last path is the one we will instantiate the base model on if the model is not found on any of the paths
		local.iEnd = ListLen(arguments.modelPaths);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.modelPath = ListGetAt(arguments.modelPaths, local.i);
			local.fileName = $objectFileName(name = arguments.name, objectPath = local.modelPath, type = arguments.type);
			if (local.fileName != arguments.type || local.i == ListLen(arguments.modelPaths)) {
				application.wheels.models[arguments.name] = $createObjectFromRoot(
					path = local.modelPath,
					fileName = local.fileName,
					method = "$initModelClass",
					name = arguments.name
				);
				local.rv = application.wheels.models[arguments.name];
				break;
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $loadRoutes() {
		$simpleLock(name = "$mapperLoadRoutes", type = "exclusive", timeout = 5, execute = "$lockedLoadRoutes");
	}

	/**
	 * Internal function.
	 */
	public void function $lockedLoadRoutes() {
		local.appKey = $appKey();
		// clear out the route info
		ArrayClear(application[local.appKey].routes);
		StructClear(application[local.appKey].namedRoutePositions);
		// load wheels internal gui routes
		// TODO skip this if mode != development|testing?
		$include(template = "/wheels/public/routes.cfm");
		// load developer routes next
		$include(template = "/config/routes.cfm");
		// set lookup info for the named routes
		$setNamedRoutePositions();
	}

	/**
	 * Internal function.
	 */
	public void function $setNamedRoutePositions() {
		local.appKey = $appKey();
		local.iEnd = ArrayLen(application[local.appKey].routes);
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.route = application[local.appKey].routes[local.i];
			if (StructKeyExists(local.route, "name") && Len(local.route.name)) {
				if (!StructKeyExists(application[local.appKey].namedRoutePositions, local.route.name)) {
					application[local.appKey].namedRoutePositions[local.route.name] = "";
				}
				application[local.appKey].namedRoutePositions[local.route.name] = ListAppend(
					application[local.appKey].namedRoutePositions[local.route.name],
					local.i
				);
			}
		}
	}

	/**
	 * Internal function.
	 */
	public void function $clearModelInitializationCache() {
		StructClear(application.wheels.models);
	}

	/**
	 * Internal function.
	 */
	public void function $clearControllerInitializationCache() {
		StructClear(application.wheels.controllers);
	}

	public string function $checkMinimumVersion(required string engine, required string version) {
		local.rv = "";
		local.version = Replace(arguments.version, ".", ",", "all");
		local.major = Val(ListGetAt(local.version, 1));
		local.minor = 0;
		local.patch = 0;
		local.build = 0;
		if (ListLen(local.version) > 1) {
			local.minor = Val(ListGetAt(local.version, 2));
		}
		if (ListLen(local.version) > 2) {
			local.patch = Val(ListGetAt(local.version, 3));
		}
		if (ListLen(local.version) > 3) {
			local.build = Val(ListGetAt(local.version, 4));
		}
		if (arguments.engine == "BoxLang") {
			local.minimumMajor = "1";
			local.minimumMinor = "0";
			local.minimumPatch = "0";
			local.maximumMajor = "1";
			local.maximumMinor = "5";
			local.maximumPatch = "999";
			
			// Check minimum version
			if (
				local.major < local.minimumMajor
				|| (local.major == local.minimumMajor && local.minor < local.minimumMinor)
				|| (local.major == local.minimumMajor && local.minor == local.minimumMinor && local.patch < local.minimumPatch)
			) {
				local.rv = "The Wheels framework requires BoxLang version #local.minimumMajor#.#local.minimumMinor#.#local.minimumPatch# or higher. You are currently running version #arguments.version#.";
			}
			
			// Check maximum version (optional - for major version compatibility)
			if (
				local.major > local.maximumMajor
				|| (local.major == local.maximumMajor && local.minor > local.maximumMinor)
				|| (local.major == local.maximumMajor && local.minor == local.maximumMinor && local.patch > local.maximumPatch)
			) {
				local.rv = "The Wheels framework has been tested up to BoxLang version #local.maximumMajor#.#local.maximumMinor#.#local.maximumPatch#. You are currently running version #arguments.version#. Please check for framework updates or compatibility issues.";
			}
		} else if (arguments.engine == "Lucee") {
			local.minimumMajor = "5";
			local.minimumMinor = "3";
			local.minimumPatch = "2";
			local.minimumBuild = "77";
			local.5 = {minimumMinor = 2, minimumPatch = 1, minimumBuild = 9};
		} else if (arguments.engine == "Adobe ColdFusion") {
			local.minimumMajor = "11";
			local.minimumMinor = "0";
			local.minimumPatch = "18";
			local.minimumBuild = "314030";
		} else if (arguments.engine == "Adobe ColdFusion") {
			local.minimumMajor = "2016";
			local.minimumMinor = "0";
			local.minimumPatch = "10";
			local.minimumBuild = "314028";
		} else if (arguments.engine == "Adobe ColdFusion") {
			local.minimumMajor = "2018";
			local.minimumMinor = "0";
			local.minimumPatch = "10";
			local.minimumBuild = "314028";
		} else {
			local.rv = false;
		}
		if (StructKeyExists(local, "minimumMajor")) {
			if (
				local.major < local.minimumMajor
				|| (local.major == local.minimumMajor && local.minor < local.minimumMinor)
				|| (local.major == local.minimumMajor && local.minor == local.minimumMinor && local.patch < local.minimumPatch)
				|| (
					local.major == local.minimumMajor
					&& local.minor == local.minimumMinor
					&& local.patch == local.minimumPatch
					&& Len(local.minimumBuild)
					&& local.build < local.minimumBuild
				)
			) {
				local.rv = local.minimumMajor & "." & local.minimumMinor & "." & local.minimumPatch;
				if (Len(local.minimumBuild)) {
					local.rv &= "." & local.minimumBuild;
				}
			}
			if (StructKeyExists(local, local.major)) {
				// special requirements for having a specific minor or patch version within a major release exists
				if (
					local.minor < local[local.major].minimumMinor
					|| (local.minor == local[local.major].minimumMinor && local.patch < local[local.major].minimumPatch)
				) {
					local.rv = local.major & "." & local[local.major].minimumMinor & "." & local[local.major].minimumPatch;
				}
			}
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public void function $loadPlugins() {
		local.appKey = $appKey();
		local.pluginPath = application[local.appKey].webPath & application[local.appKey].pluginPath;
		application[local.appKey].PluginObj = $createObjectFromRoot(
			path = "wheels",
			fileName = "Plugins",
			method = "$init",
			pluginPath = local.pluginPath,
			deletePluginDirectories = application[local.appKey].deletePluginDirectories,
			overwritePlugins = application[local.appKey].overwritePlugins,
			loadIncompatiblePlugins = application[local.appKey].loadIncompatiblePlugins,
			wheelsEnvironment = application[local.appKey].environment,
			wheelsVersion = application[local.appKey].version
		);
		application[local.appKey].plugins = application[local.appKey].PluginObj.getPlugins();
		application[local.appKey].pluginMeta = application[local.appKey].PluginObj.getPluginMeta();
		application[local.appKey].incompatiblePlugins = application[local.appKey].PluginObj.getIncompatiblePlugins();
		application[local.appKey].dependantPlugins = application[local.appKey].PluginObj.getDependantPlugins();
		application[local.appKey].mixins = application[local.appKey].PluginObj.getMixins();
	}

	/**
	 * Internal function.
	 */
	public string function $appKey() {
		local.rv = "wheels";
		if (StructKeyExists(application, "$wheels")) {
			local.rv = "$wheels";
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $singularizeOrPluralize(
		required string text,
		required string which,
		numeric count = -1,
		boolean returnCount = true
	) {
		// by default we pluralize/singularize the entire string
		local.text = arguments.text;

		// keep track of the success of any rule matches
		local.ruleMatched = false;

		// when count is 1 we don't need to pluralize at all so just set the return value to the input string
		local.rv = local.text;

		if (arguments.count != 1) {
			if (ReFind("[A-Z]", local.text)) {
				// only pluralize/singularize the last part of a camelCased variable (e.g. in "websiteStatusUpdate" we only change the "update" part)
				// also set a variable with the unchanged part of the string (to be prepended before returning final result)
				local.upperCasePos = ReFind("[A-Z]", Reverse(local.text));
				local.prepend = Mid(local.text, 1, Len(local.text) - local.upperCasePos);
				local.text = Reverse(Mid(Reverse(local.text), 1, local.upperCasePos));
			}

			// Get global settings for uncountable and irregular words.
			// For the irregular ones we need to convert them from a struct to a list.
			local.uncountables = $listClean($get("uncountables"));
			local.irregulars = "";
			local.words = $get("irregulars");
			for (local.word in local.words) {
				local.irregulars = ListAppend(local.irregulars, LCase(local.word));
				local.irregulars = ListAppend(local.irregulars, local.words[local.word]);
			}

			if (ListFindNoCase(local.uncountables, local.text)) {
				local.rv = local.text;
				local.ruleMatched = true;
			} else if (ListFindNoCase(local.irregulars, local.text)) {
				local.pos = ListFindNoCase(local.irregulars, local.text);
				if (arguments.which == "singularize" && local.pos % 2 == 0) {
					local.rv = ListGetAt(local.irregulars, local.pos - 1);
				} else if (arguments.which == "pluralize" && local.pos % 2 != 0) {
					local.rv = ListGetAt(local.irregulars, local.pos + 1);
				} else {
					local.rv = local.text;
				}
				local.ruleMatched = true;
			} else {
				if (arguments.which == "pluralize") {
					local.ruleList = "(quiz)$,\1zes,^(ox)$,\1en,([m|l])ouse$,\1ice,(matr|vert|ind)ix|ex$,\1ices,(x|ch|ss|sh)$,\1es,([^aeiouy]|qu)y$,\1ies,(hive)$,\1s,(?:([^f])fe|([lr])f)$,\1\2ves,sis$,ses,([ti])um$,\1a,(buffal|tomat|potat|volcan|her)o$,\1oes,(bu)s$,\1ses,(alias|status)$,\1es,(octop|vir)us$,\1i,(ax|test)is$,\1es,s$,s,$,s";
				} else if (arguments.which == "singularize") {
					local.ruleList = "(quiz)zes$,\1,(matr)ices$,\1ix,(vert|ind)ices$,\1ex,^(ox)en,\1,(alias|status)es$,\1,([octop|vir])i$,\1us,(cris|ax|test)es$,\1is,(shoe)s$,\1,(o)es$,\1,(bus)es$,\1,([m|l])ice$,\1ouse,(x|ch|ss|sh)es$,\1,(m)ovies$,\1ovie,(s)eries$,\1eries,([^aeiouy]|qu)ies$,\1y,([lr])ves$,\1f,(tive)s$,\1,(hive)s$,\1,([^f])ves$,\1fe,(^analy)ses$,\1sis,((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$,\1\2sis,([ti])a$,\1um,(n)ews$,\1ews,(.*)?ss$,\1ss,s$,#Chr(7)#";
				}
				local.rules = ArrayNew(2);
				local.count = 1;
				local.iEnd = ListLen(local.ruleList);
				for (local.i = 1; local.i <= local.iEnd; local.i = local.i + 2) {
					local.rules[local.count][1] = ListGetAt(local.ruleList, local.i);
					local.rules[local.count][2] = ListGetAt(local.ruleList, local.i + 1);
					local.count = local.count + 1;
				}
				local.iEnd = ArrayLen(local.rules);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					if (ReFindNoCase(local.rules[local.i][1], local.text)) {
						local.rv = ReReplaceNoCase(local.text, local.rules[local.i][1], local.rules[local.i][2]);
						local.ruleMatched = true;
						break;
					}
				}
				local.rv = Replace(local.rv, Chr(7), "", "all");
			}

			// this was a camelCased string and we need to prepend the unchanged part to the result
			if (StructKeyExists(local, "prepend") && local.ruleMatched) {
				local.rv = local.prepend & local.rv;
			}
		}

		// return the count number in the string (e.g. "5 sites" instead of just "sites")
		if (arguments.returnCount && arguments.count != -1) {
			local.rv = LsNumberFormat(arguments.count) & " " & local.rv;
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 */
	public string function $prependUrl(
		required string path,
		string host = "",
		string protocol = "",
		numeric port = 0
	) {
		local.rv = arguments.path;
		if (arguments.port != 0) {
			// use the port that was passed in by the developer
			local.rv = ":" & arguments.port & local.rv;
		} else if (request.cgi.server_port != 80 && request.cgi.server_port != 443) {
			// if the port currently in use is not 80 or 443 we set it explicitly in the URL
			local.rv = ":" & request.cgi.server_port & local.rv;
		}
		if (Len(arguments.host)) {
			local.rv = arguments.host & local.rv;
		} else {
			local.rv = request.cgi.server_name & local.rv;
		}
		if (Len(arguments.protocol)) {
			local.rv = arguments.protocol & "://" & local.rv;
		} else if (request.cgi.http_x_forwarded_proto == "https" || request.cgi.server_port_secure == "true") {
			local.rv = "https://" & local.rv;
		} else {
			local.rv = "http://" & local.rv;
		}
		return local.rv;
	}

	/**
	 * NB: url rewriting files need to be removed from here.
	 */
	public string function $buildReleaseZip(string version = application.wheels.version, string directory = ExpandPath("/")) {
		local.name = "wheels-" & LCase(Replace(arguments.version, " ", "-", "all"));
		local.name = Replace(local.name, "alpha-", "alpha.");
		local.name = Replace(local.name, "beta-", "beta.");
		local.name = Replace(local.name, "rc-", "rc.");
		local.path = arguments.directory & local.name & ".zip";

		// directories & files to add to the zip
		local.include = [
			"/config",
			"/app/controllers",
			"/app/events",
			"/app/lib",
			"/app/migrator",
			"files",
			"/app/global",
			"images",
			"javascripts",
			"miscellaneous",
			"/app/models",
			"/plugins",
			"stylesheets",
			"/tests",
			"/app/views",
			"/vendor/wheels",
			"Application.cfc",
			"../box.json",
			"index.cfm"
		];

		// directories & files to be removed
		local.exclude = ["/wheels/tests", "/wheels/public/build.cfm", "/wheels/tests_testbox"];

		// filter out these bad boys
		local.filter = "*.settings, *.classpath, *.project, *.DS_Store";

		// The change log and license are copied to the wheels directory only for the build.
		// FileCopy(ExpandPath("CHANGELOG.md"), ExpandPath("/wheels/CHANGELOG.md"));
		// FileCopy(ExpandPath("LICENSE"), ExpandPath("/wheels/LICENSE"));

		// Entries starting with "/" or ".." → treat as project-root paths (keep original folder structure)
		// Entries without "/" → treat as webroot (/public) paths
		for (local.i in local.include) {
			if (FileExists(ExpandPath(local.i))) {
				if(left(local.i,1) neq "/" && left(local.i,2) neq ".."){
					$zip(file = local.path, source = ExpandPath(local.i), prefix = "/public");
				} else {
					$zip(file = local.path, source = ExpandPath(local.i));
				}
			} else if (DirectoryExists(ExpandPath(local.i))) {
				if(left(local.i,1) neq "/" && left(local.i,2) neq ".."){
					$zip(file = local.path, source = ExpandPath(local.i), prefix = "/public/#local.i#");
				} else {
					$zip(file = local.path, source = ExpandPath(local.i), prefix = local.i);
				}
			} else {
				Throw(
					type = "Wheels.Build",
					message = "#ExpandPath(local.i)# not found",
					detail = "All paths specified in local.include must exist"
				);
			}
		};

		for (local.i in local.exclude) {
			$zip(file = local.path, action = "delete", entrypath = local.i);
		};
		$zip(file = local.path, action = "delete", filter = local.filter, recurse = true);

		// Clean up.
		/* Might not need this because the wheels folder is outside the app now */
		// FileDelete(ExpandPath("/wheels/CHANGELOG.md"));
		// FileDelete(ExpandPath("/wheels/LICENSE"));

		return local.path;
	}

	/**
	 * Throw a developer friendly Wheels error if set (typically in development mode).
	 * Otherwise show the 404 page for end users (typically in production mode).
	 */
	public void function $throwErrorOrShow404Page(required string type, required string message, string extendedInfo = "") {
		$header(statusCode = 404, statustext = "Not Found");
		if ($get("showErrorInformation")) {
			Throw(type = arguments.type, message = arguments.message, extendedInfo = arguments.extendedInfo);
		} else {
			local.template = $get("eventPath") & "/onmissingtemplate.cfm";
			$includeAndOutput(template = local.template);
			abort;
		}
	}

	/**
	 * Wildcard domain match: check if the current cgi.server_name and port satisfies
	 * the passed in domain string whilst checking for wildcards
	 *
	 * @domain string to test against e.g *.foo.com
	 * @cgi Fake CGI Scope for Testing; will default to normal cgi scope
	 */
	public boolean function $wildcardDomainMatchCGI(required string domain, struct cgi) {
		local.domain = arguments.domain;
		local.cgi = StructKeyExists(arguments, "cgi") ? arguments.cgi : $cgiScope();

		return $wildcardDomainMatch($fullDomainString(local.domain), $fullCgiDomainString(local.cgi));
	}

	/**
	 * Wildcard domain match: domain satisfies wildcard
	 *
	 * @domain string to test against e.g *.foo.com
	 * @origin string to test against e.g bar.foo.com
	 */
	public boolean function $wildcardDomainMatch(required string domain, required string origin) {
		local.rv = false;
		local.domainfull = $fullDomainString(arguments.domain);
		local.originfull = $fullDomainString(arguments.origin);

		// Do we have a wildcard subdomain?
		local.hasWildcard = ListContainsNoCase(local.domainfull, "*", '.') && Len(local.domainfull > 1);

		// If not, is it an exact match?
		if (!local.hasWildcard && local.domainfull == local.originfull) {
			local.rv = true;
		}

		// Loop over domain backwards and test the corresponding position in the other array
		if (local.hasWildcard) {
			local.domainReversed = ListToArray(Reverse(SpanExcluding(Reverse(local.domainfull), ".")));
			local.serverNameReversed = ListToArray(Reverse(SpanExcluding(Reverse(local.originfull), ".")));
			local.wildcardPassed = true;
			// Check each part with corresponding part in other array
			for (local.i = 1; i LTE ArrayLen(local.domainReversed); i = i + 1) {
				if (local.domainReversed[i] != local.serverNameReversed[i] && local.domainReversed[i] DOES NOT CONTAIN '*') {
					local.wildcardPassed = false;
					break;
				}
			}
			local.rv = local.wildcardPassed;
		}

		return local.rv;
	}

	/**
	 * Get full domain string from cgi scope: includes protocol and port
	 * e.g https://www.cfwheels.com:443
	 *
	 * @cgi Fake CGI Scope for Testing; will default to normal cgi scope
	 **/
	public string function $fullCgiDomainString(struct cgi) {
		local.cgi = StructKeyExists(arguments, "cgi") ? arguments.cgi : $cgiScope();
		local.server_name = local.cgi.server_name;
		local.server_port = local.cgi.server_port;
		local.server_protocol =
		(
			(StructKeyExists(local.cgi, 'http_x_forwarded_proto') && local.cgi.http_x_forwarded_proto == "https")
			|| (StructKeyExists(local.cgi, 'server_port_secure') && local.cgi.server_port_secure)
		)
		 ? "https" : "http";
		return local.server_protocol & '://' & local.server_name & ':' & local.server_port;
	}

	/**
	 * Get full domain string from a passed in string: includes protocol and port
	 * e.g https://www.cfwheels.com -> https://www.cfwheels.com:443
	 * e.g www.cfwheels.com -> http://www.cfwheels.com:80
	 *
	 * @domain The string to look at
	 **/
	public string function $fullDomainString(required string domain) {
		local.domain = arguments.domain;
		local.protocol = ListFirst(local.domain, "://");
		local.port = ListLast(local.domain, ":");

		if (!ListFindNoCase("http,https", local.protocol)) {
			if (local.port == 443) {
				local.protocol = "https";
			} else {
				local.protocol = "http";
			}
			local.domain = local.protocol & '://' & local.domain;
		}
		if (!IsNumeric(local.port)) {
			if (local.protocol == 'http') {
				local.port = 80;
			} else if (local.protocol == 'https') {
				local.port = 443;
			}
			local.domain &= ':' & local.port;
		}
		return local.domain;
	}

	/**
	 * Set CORS Headers: only triggered if application.wheels.allowCorsRequests = true
	 */
	public void function $setCORSHeaders(
		string allowOrigin = "*",
		string allowCredentials = false,
		string allowHeaders = "Origin, Content-Type, X-Auth-Token, X-Requested-By, X-Requested-With",
		string allowMethods = "GET, POST, PATCH, PUT, DELETE, OPTIONS",
		boolean allowMethodsByRoute = false,
		string pathInfo = request.cgi.PATH_INFO,
		string scriptName = request.cgi.script_name
	) {
		local.incomingOrigin = StructKeyExists(request.wheels.httprequestdata.headers, "origin") ? request.wheels.httprequestdata.headers.origin : false;

		// Either a wildcard, or if a specific domain is set, we need to ensure the incoming request matches it
		if (arguments.allowOrigin == "*") {
			$header(name = "Access-Control-Allow-Origin", value = arguments.allowOrigin);
		} else {
			// Passed value may be a list or just a single entry
			local.originArr = ListToArray(arguments.allowOrigin);

			// Is this origin in the allowed Array?
			for (local.o in local.originArr) {
				if ($wildcardDomainMatch(local.o, local.incomingOrigin)) {
					$header(name = "Access-Control-Allow-Origin", value = local.incomingOrigin);
					$header(name = "Vary", value = "Origin");
					break;
				}
			}
		}

		// Set Origin, Content-Type, X-Auth-Token, X-Requested-By, X-Requested-With Allow Headers
		$header(name = "Access-Control-Allow-Headers", value = arguments.allowHeaders);

			// Either Look up Route specific allowed methods, or just use default
		if (arguments.allowMethodsByRoute) {
			local.permittedMethods = [];

			// NB this is basically duplicate logic: needs refactoring
			if (arguments.pathInfo == arguments.scriptName || arguments.pathInfo == "/" || !Len(arguments.pathInfo)) {
				local.path = "";
			} else {
				local.path = Right(arguments.pathInfo, Len(arguments.pathInfo) - 1);
			}

			// Attempt to match the requested route and only display the allowed methods for that route
			// Does this info already exist in scope? It seems silly to have to look it up again
			for (local.route in application.wheels.routes) {
				// Make sure route has been converted to regular expression.
				if (!StructKeyExists(local.route, "regex")) {
					local.route.regex = application.wheels.mapper.$patternToRegex(local.route.pattern);
				}

				// If route matches regular expression, get the methods
				if (ReFindNoCase(local.route.regex, local.path)) {
					ArrayAppend(local.permittedMethods, local.route.methods);
				}
			}
			if (ArrayLen(local.permittedMethods)) {
				$header(name = "Access-Control-Allow-Methods", value = UCase(ArrayToList(local.permittedMethods, ', ')));
			}
		} else {
			$header(name = "Access-Control-Allow-Methods", value = arguments.allowMethods);
		}

		// Only add this header if requested (false is an invalid value)
		if (arguments.allowCredentials) {
			$header(name = "Access-Control-Allow-Credentials", value = true);
		}
	}

	/**
	 * Restore the application scope modified by the test runner
	 */
	public void function $restoreTestRunnerApplicationScope() {
		if (StructKeyExists(request, "wheels") && StructKeyExists(request.wheels, "testRunnerApplicationScope")) {
			application.wheels = request.wheels.testRunnerApplicationScope;
		}
	}

	/**
	 * Returns the request timeout value in seconds
	 */
	public numeric function $getRequestTimeout() {
		// Check for BoxLang first using unique BoxLang identifier
		if (StructKeyExists(server, "boxlang")) {
			return 10000;
		} else if (StructKeyExists(server, "lucee") && StructKeyExists(server.lucee, "version")) {
			return (GetPageContext().getRequestTimeout() / 1000);
		} else {
			return CreateObject("java", "coldfusion.runtime.RequestMonitor").GetRequestTimeout();
		}
	}

	/**
	 * Returns an associated MIME type based on a file extension.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @extension The extension to get the MIME type for.
	 * @fallback The fallback MIME type to return.
	 */
	public string function mimeTypes(required string extension, string fallback = "application/octet-stream") {
		local.rv = arguments.fallback;
		if (StructKeyExists(application.wheels.mimetypes, arguments.extension)) {
			local.rv = application.wheels.mimetypes[arguments.extension];
		}
		return local.rv;
	}

	/**
	 * Truncates text to the specified length and replaces the last characters with the specified truncate string (which defaults to "...").
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @text The text to truncate.
	 * @length Length to truncate the text to.
	 * @truncateString String to replace the last characters with.
	 */
	public string function truncate(required string text, numeric length, string truncateString) {
		$args(name = "truncate", args = arguments);
		if (Len(arguments.text) > arguments.length) {
			local.rv = Left(arguments.text, arguments.length - Len(arguments.truncateString)) & arguments.truncateString;
		} else {
			local.rv = arguments.text;
		}
		return local.rv;
	}

	/**
	 * Truncates text to the specified length of words and replaces the remaining characters with the specified truncate string (which defaults to "...").
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @text The text to truncate.
	 * @length Number of words to truncate the text to.
	 * @truncateString String to replace the last characters with.
	 */
	public string function wordTruncate(required string text, numeric length, string truncateString) {
		$args(name = "wordTruncate", args = arguments);
		local.words = ListToArray(arguments.text, " ", false);

		// When there are fewer (or same) words in the string than the number to be truncated we can just return it unchanged.
		if (ArrayLen(local.words) <= arguments.length) {
			return arguments.text;
		}

		local.rv = "";
		local.iEnd = arguments.length;
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.rv = ListAppend(local.rv, local.words[local.i], " ");
		}
		local.rv &= arguments.truncateString;
		return local.rv;
	}

	/**
	 * Extracts an excerpt from text that matches the first instance of a given phrase.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @text The text to extract an excerpt from.
	 * @phrase The phrase to extract.
	 * @radius Number of characters to extract surrounding the phrase.
	 * @excerptString String to replace first and / or last characters with.
	 */
	public string function excerpt(required string text, required string phrase, numeric radius, string excerptString) {
		$args(name = "excerpt", args = arguments);
		local.pos = FindNoCase(arguments.phrase, arguments.text, 1);

		// Return an empty value if the text wasn't found at all.
		if (!local.pos) {
			return "";
		}

		// Set start info based on whether the excerpt text found, including its radius, comes before the start of the string.
		if ((local.pos - arguments.radius) <= 1) {
			local.startPos = 1;
			local.truncateStart = "";
		} else {
			local.startPos = local.pos - arguments.radius;
			local.truncateStart = arguments.excerptString;
		}

		// Set end info based on whether the excerpt text found, including its radius, comes after the end of the string.
		if ((local.pos + Len(arguments.phrase) + arguments.radius) > Len(arguments.text)) {
			local.endPos = Len(arguments.text);
			local.truncateEnd = "";
		} else {
			local.endPos = local.pos + arguments.radius;
			local.truncateEnd = arguments.excerptString;
		}

		local.len = (local.endPos + Len(arguments.phrase)) - local.startPos;
		local.mid = Mid(arguments.text, local.startPos, local.len);
		local.rv = local.truncateStart & local.mid & local.truncateEnd;
		return local.rv;
	}

	/**
	 * Pass in two dates to this method, and it will return a string describing the difference between them.
	 *
	 * [section: Global Helpers]
	 * [category: Date Functions]
	 *
	 * @fromTime Date to compare from.
	 * @toTime Date to compare to.
	 * @includeSeconds Whether or not to include the number of seconds in the returned string.
	 */
	public string function distanceOfTimeInWords(required date fromTime, required date toTime, boolean includeSeconds) {
		$args(name = "distanceOfTimeInWords", args = arguments);
		local.minuteDiff = DateDiff("n", arguments.fromTime, arguments.toTime);
		local.secondDiff = DateDiff("s", arguments.fromTime, arguments.toTime);
		local.hours = 0;
		local.days = 0;
		local.rv = "";
		if (local.minuteDiff <= 1) {
			if (local.secondDiff < 60) {
				local.rv = "less than a minute";
			} else {
				local.rv = "1 minute";
			}
			if (arguments.includeSeconds) {
				if (local.secondDiff < 5) {
					local.rv = "less than 5 seconds";
				} else if (local.secondDiff < 10) {
					local.rv = "less than 10 seconds";
				} else if (local.secondDiff < 20) {
					local.rv = "less than 20 seconds";
				} else if (local.secondDiff < 40) {
					local.rv = "half a minute";
				}
			}
		} else if (local.minuteDiff < 45) {
			local.rv = local.minuteDiff & " minutes";
		} else if (local.minuteDiff < 90) {
			local.rv = "about 1 hour";
		} else if (local.minuteDiff < 1440) {
			local.hours = Ceiling(local.minuteDiff / 60);
			local.rv = "about " & local.hours & " hours";
		} else if (local.minuteDiff < 2880) {
			local.rv = "1 day";
		} else if (local.minuteDiff < 43200) {
			local.days = Int(local.minuteDiff / 1440);
			local.rv = local.days & " days";
		} else if (local.minuteDiff < 86400) {
			local.rv = "about 1 month";
		} else if (local.minuteDiff < 525600) {
			local.months = Int(local.minuteDiff / 43200);
			local.rv = local.months & " months";
		} else if (local.minuteDiff < 657000) {
			local.rv = "about 1 year";
		} else if (local.minuteDiff < 919800) {
			local.rv = "over 1 year";
		} else if (local.minuteDiff < 1051200) {
			local.rv = "almost 2 years";
		} else if (local.minuteDiff >= 1051200) {
			local.years = Int(local.minuteDiff / 525600);
			local.rv = "over " & local.years & " years";
		}
		return local.rv;
	}

	/**
	 * Returns a string describing the approximate time difference between the date passed in and the current date.
	 *
	 * [section: Global Helpers]
	 * [category: Date Functions]
	 *
	 * @fromTime Date to compare from.
	 * @includeSeconds Whether or not to include the number of seconds in the returned string.
	 * @toTime Date to compare to.
	 */
	public any function timeAgoInWords(required date fromTime, boolean includeSeconds, date toTime = Now()) {
		$args(name = "timeAgoInWords", args = arguments);
		return distanceOfTimeInWords(argumentCollection = arguments);
	}

	/**
	 * Returns a string describing the approximate time difference between the current date and the date passed in.
	 *
	 * [section: Global Helpers]
	 * [category: Date Functions]
	 *
	 * @toTime Date to compare to.
	 * @includeSeconds Whether or not to include the number of seconds in the returned string.
	 * @fromTime Date to compare from.
	 */
	public string function timeUntilInWords(required date toTime, boolean includeSeconds, date fromTime = Now()) {
		$args(name = "timeUntilInWords", args = arguments);
		return distanceOfTimeInWords(argumentCollection = arguments);
	}

	/**
	 * Returns the current setting for the supplied Wheels setting or the current default for the supplied Wheels function argument.
	 *
	 * [section: Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @name Variable name to get setting for.
	 * @functionName Function name to get setting for.
	 */
	public any function get(required string name, string functionName = "") {
		return $get(argumentCollection = arguments);
	}

	/**
	 * Use to configure a global setting or set a default for a function.
	 *
	 * [section: Configuration]
	 * [category: Miscellaneous Functions]
	 */
	public void function set() {
		$set(argumentCollection = arguments);
	}

	/**
	 * Adds a new MIME type to your Wheels application for use with responding to multiple formats.
	 *
	 * [section: Configuration]
	 * [category: Miscellaneous Functions]
	 *
	 * @extension File extension to add.
	 * @mimeType Matching MIME type to associate with the file extension.
	 */
	public void function addFormat(required string extension, required string mimeType) {
		local.appKey = $appKey();
		application[local.appKey].formats[arguments.extension] = arguments.mimeType;
	}

	/**
	 * Returns the mapper object used to configure your application's routes. Usually you will use this method in `config/routes.cfm` to start chaining route mapping methods like `resources`, `namespace`, etc.
	 *
	 * [section: Configuration]
	 * [category: Routing]
	 *
	 * @restful Whether to turn on RESTful routing or not. Not recommended to set. Will probably be removed in a future version of wheels, as RESTful routes are the default.
	 * @methods If not RESTful, then specify allowed routes. Not recommended to set. Will probably be removed in a future version of wheels, as RESTful routes are the default.
	 * @mapFormat This is useful for providing formats via URL like `json`, `xml`, `pdf`, etc. Set to false to disable automatic .[format] generation for resource based routes
	 */
	public struct function mapper(boolean restful = true, boolean methods = arguments.restful, boolean mapFormat = true) {
		return application[$appKey()].mapper.$draw(argumentCollection = arguments);
	}

	/**
	 * Creates a controller and calls an action on it.
	 * Which controller and action that's called is determined by the params passed in.
	 * Returns the result of the request either as a string or in a struct with `body`, `emails`, `files`, `flash`, `redirect`, `status`, and `type`.
	 * Primarily used for testing purposes.
	 *
	 * [section: Controller]
	 * [category: Miscellaneous Functions]
	 *
	 * @params The params struct to use in the request (make sure that at least `controller` and `action` are set).
	 * @method The HTTP method to use in the request (`get`, `post` etc).
	 * @returnAs Pass in `struct` to return all information about the request instead of just the final output (`body`).
	 * @rollback Pass in `true` to roll back all database transactions made during the request.
	 * @includeFilters Set to `before` to only execute "before" filters, `after` to only execute "after" filters or `false` to skip all filters.
	 */
	public any function processRequest(
		required struct params,
		string method,
		string returnAs,
		string rollback,
		string includeFilters = true
	) {
		$args(name = "processRequest", args = arguments);

		// Set the global transaction mode to rollback when specified.
		// Also save the current state so we can set it back after the tests have run.
		if (arguments.rollback) {
			local.transactionMode = $get("transactionMode");
			$set(transactionMode = "rollback");
		}

		// Before proceeding we set the request method to our internal CGI scope if passed in.
		// This way it's possible to mock a POST request so that an isPost() call in the action works as expected for example.
		if (arguments.method != "get") {
			request.cgi.request_method = arguments.method;
		}

		// Look up controller & action via route name and method
		if (StructKeyExists(arguments.params, "route")) {
			local.route = $findRoute(argumentCollection = arguments.params, method = arguments.method);
			arguments.params.controller = local.route.controller;
			arguments.params.action = local.route.action;
		}

		// Never deliver email or send files during test.
		local.deliverEmail = $get(functionName = "sendEmail", name = "deliver");
		$set(functionName = "sendEmail", deliver = false);
		local.deliverFile = $get(functionName = "sendFile", name = "deliver");
		$set(functionName = "sendFile", deliver = false);

		local.controller = controller(name = arguments.params.controller, params = arguments.params);

		// Set to ignore CSRF errors during testing.
		local.controller.protectsFromForgery(with = "ignore");

		local.controller.processAction(includeFilters = arguments.includeFilters);
		local.response = local.controller.response();

		// Get redirect info.
		// If a delayed redirect was made we use the status code for that and set the body to a blank string.
		// If not we use the current status code and response and set the redirect info to a blank string.
		local.redirectDetails = local.controller.getRedirect();
		if (StructCount(local.redirectDetails)) {
			local.body = "";
			local.redirect = local.redirectDetails.url;
			local.status = local.redirectDetails.statusCode;
		} else {
			local.status = $statusCode();
			local.body = local.response;
			local.redirect = "";
		}

		if (arguments.returnAs == "struct") {
			local.rv = {
				body = local.body,
				emails = local.controller.getEmails(),
				files = local.controller.getFiles(),
				flash = local.controller.flash(),
				redirect = local.redirect,
				status = local.status,
				type = $contentType()
			};
		} else {
			local.rv = local.body;
		}

		// Clear the Flash so we can run several processAction calls without the Flash sticking around.
		local.controller.$flashClear();

		// Set back the global transaction mode to the previous value if it has been changed.
		if (arguments.rollback) {
			$set(transactionMode = local.transactionMode);
		}

		// Set back the request method to GET (this is fine since the test suite is always run using GET).
		request.cgi.request_method = "get";

		// Set back email delivery setting to previous value.
		$set(functionName = "sendEmail", deliver = local.deliverEmail);
		$set(functionName = "sendFile", deliver = local.deliverFile);

		// Set back the status code to 200 so the test suite does not use the same code that the action that was tested did.
		// If the test suite fails it will set the status code to 500 later.
		$header(statusCode = 200, statusText = "OK");

		// Set the Content-Type header in case it was set to something else (e.g. application/json) during processing.
		// It's fine to do this because we always want to return the test page as text/html.
		$header(name = "Content-Type", value = "text/html", charset = "UTF-8");

		return local.rv;
	}

	/**
	 * Returns a struct with information about the specified paginated query.
	 * The keys that will be included in the struct are `currentPage`, `totalPages` and `totalRecords`.
	 *
	 * [section: Controller]
	 * [category: Pagination Functions]
	 *
	 * @handle The handle given to the query to return pagination information for.
	 */
	public struct function pagination(string handle = "query") {
		if ($get("showErrorInformation")) {
			if (!StructKeyExists(request.wheels, arguments.handle)) {
				Throw(
					type = "Wheels.QueryHandleNotFound",
					message = "Wheels couldn't find a query with the handle of `#arguments.handle#`.",
					extendedInfo = "Make sure your `findAll` call has the `page` argument specified and matching `handle` argument if specified."
				);
			}
		}
		return request.wheels[arguments.handle];
	}

	/**
	 * Allows you to set a pagination handle for a custom query so you can perform pagination on it in your view with `paginationLinks`.
	 *
	 * [section: Controller]
	 * [category: Pagination Functions]
	 *
	 * @totalRecords Total count of records that should be represented by the paginated links.
	 * @currentPage Page number that should be represented by the data being fetched and the paginated links.
	 * @perPage Number of records that should be represented on each page of data.
	 * @handle Name of handle to reference in `paginationLinks`.
	 */
	public void function setPagination(
		required numeric totalRecords,
		numeric currentPage = 1,
		numeric perPage = 25,
		string handle = "query"
	) {
		// NOTE: this should be documented as a controller function but needs to be placed here because the findAll() method calls it.

		// All numeric values must be integers.
		arguments.totalRecords = Fix(arguments.totalRecords);
		arguments.currentPage = Fix(arguments.currentPage);
		arguments.perPage = Fix(arguments.perPage);

		// The totalRecords argument cannot be negative.
		if (arguments.totalRecords < 0) {
			arguments.totalRecords = 0;
		}

		// Default perPage to 25 if it's less then zero.
		if (arguments.perPage <= 0) {
			arguments.perPage = 25;
		}

		// Calculate the total pages the query will have.
		arguments.totalPages = Ceiling(arguments.totalRecords / arguments.perPage);

		// The currentPage argument shouldn't be less then 1 or greater then the number of pages.
		if (arguments.currentPage >= arguments.totalPages) {
			arguments.currentPage = arguments.totalPages;
		}
		if (arguments.currentPage < 1) {
			arguments.currentPage = 1;
		}

		// As a convenience for cfquery and cfloop when doing oldschool type pagination.
		// Set startrow for cfquery and cfloop.
		arguments.startRow = (arguments.currentPage * arguments.perPage) - arguments.perPage + 1;

		// Set maxrows for cfquery.
		arguments.maxRows = arguments.perPage;

		// Set endrow for cfloop.
		arguments.endRow = (arguments.startRow - 1) + arguments.perPage;

		// The endRow argument shouldn't be greater then the totalRecords or less than startRow.
		if (arguments.endRow >= arguments.totalRecords) {
			arguments.endRow = arguments.totalRecords;
		}
		if (arguments.endRow < arguments.startRow) {
			arguments.endRow = arguments.startRow;
		}

		local.args = Duplicate(arguments);
		StructDelete(local.args, "handle");
		request.wheels[arguments.handle] = local.args;
	}

	/**
	 * Creates and returns a controller object with your own custom name and params.
	 * Used primarily for testing purposes.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @name Name of the controller to create.
	 * @params The params struct (combination of form and URL variables).
	 */
	public any function controller(required string name, struct params = {}) {
		local.args = {};
		local.args.name = arguments.name;

		local.rv = $doubleCheckedLock(
			condition = "$cachedControllerClassExists",
			conditionArgs = local.args,
			execute = "$createControllerClass",
			executeArgs = local.args,
			name = "controllerLock#application.applicationName#"
		);
		if (!StructIsEmpty(arguments.params)) {
			local.rv = local.rv.$createControllerObject(arguments.params);
		}
		return local.rv;
	}

	/**
	 * Returns a reference to the requested model so that class level methods can be called on it.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @name Name of the model to get a reference to.
	 */
	public any function model(required string name) {
		return $doubleCheckedLock(
			condition = "$cachedModelClassExists",
			conditionArgs = arguments,
			execute = "$createModelClass",
			executeArgs = arguments,
			name = "modelLock#application.applicationName#"
		);
	}

	/**
	 * Obfuscates a value. Typically used for hiding primary key values when passed along in the URL.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @param The value to obfuscate.
	 */
	public string function obfuscateParam(required any param) {
		local.rv = arguments.param;
		local.param = ArrayToList(ReMatch("[0-9]+", arguments.param), "");
		if (Len(local.param) && local.param > 0 && Left(local.param, 1) != 0) {
			local.iEnd = Len(local.param);
			local.a = (10^local.iEnd) + Reverse(local.param);
			local.b = 0;
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.b += Left(Right(local.param, local.i), 1);
			}
			if (IsValid("integer", local.a)) {
				local.rv = FormatBaseN(local.b + 154, 16) & FormatBaseN(BitXor(local.a, 461), 16);
			}
		}
		return local.rv;
	}

	/**
	 * Deobfuscates a value.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @param The value to deobfuscate.
	 */
	public string function deobfuscateParam(required string param) {
		if (Val(arguments.param) != arguments.param) {
			try {
				local.checksum = Left(arguments.param, 2);
				local.rv = Right(arguments.param, Len(arguments.param) - 2);
				local.z = BitXor(InputBaseN(local.rv, 16), 461);
				local.rv = "";
				local.iEnd = Len(local.z) - 1;
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.rv &= Left(Right(local.z, local.i), 1);
				}
				local.checkSumTest = 0;
				local.iEnd = Len(local.rv);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.checkSumTest += Left(Right(local.rv, local.i), 1);
				}
				local.c1 = ToString(FormatBaseN(local.checkSumTest + 154, 10));
				local.c2 = InputBaseN(local.checksum, 16);
				if (local.c1 != local.c2) {
					local.rv = arguments.param;
				}
			} catch (any e) {
				local.rv = arguments.param;
			}
		} else {
			local.rv = arguments.param;
		}
		return local.rv;
	}

	/**
	 * Returns a list of the names of all installed plugins.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 */
	public string function pluginNames() {
		return StructKeyList(application.wheels.plugins);
	}

	/**
	 * Creates an internal URL based on supplied arguments.
	 *
	 * [section: Global Helpers]
	 * [category: Miscellaneous Functions]
	 *
	 * @route Name of a route that you have configured in `config/routes.cfm`.
	 * @controller Name of the controller to include in the URL.
	 * @action Name of the action to include in the URL.
	 * @key Key(s) to include in the URL.
	 * @params Any additional parameters to be set in the query string (example: `wheels=cool&x=y`). Please note that Wheels uses the `&` and `=` characters to split the parameters and encode them properly for you. However, if you need to pass in `&` or `=` as part of the value, then you need to encode them (and only them), example: `a=cats%26dogs%3Dtrouble!&b=1`.
	 * @anchor Sets an anchor name to be appended to the path.
	 * @onlyPath If `true`, returns only the relative URL (no protocol, host name or port).
	 * @host Set this to override the current host.
	 * @protocol Set this to override the current protocol.
	 * @port Set this to override the current port number.
	 * @encode Encode URL parameters using `EncodeForURL()`. Please note that this does not make the string safe for placement in HTML attributes, for that you need to wrap the result in `EncodeForHtmlAttribute()` or use `linkTo()`, `startFormTag()` etc instead.
	 */
	public string function URLFor(
		string route = "",
		string controller = "",
		string action = "",
		any key = "",
		string params = "",
		string anchor = "",
		boolean onlyPath,
		string host,
		string protocol,
		numeric port,
		boolean encode,
		boolean $encodeForHtmlAttribute = false,
		string $URLRewriting = application.wheels.URLRewriting
	) {
		$args(name = "URLFor", args = arguments);
		local.coreVariables = "controller,action,key,format";
		local.params = {};
		if (StructKeyExists(variables, "params")) {
			StructAppend(local.params, variables.params);
		}

		// Throw error if host or protocol are passed with onlyPath=true.
		local.hostOrProtocolNotEmpty = Len(arguments.host) || Len(arguments.protocol);
		if (application.wheels.showErrorInformation && arguments.onlyPath && local.hostOrProtocolNotEmpty) {
			Throw(
				type = "Wheels.IncorrectArguments",
				message = "Can't use the `host` or `protocol` arguments when `onlyPath` is `true`.",
				extendedInfo = "Set `onlyPath` to `false` so that `linkTo` will create absolute URLs and thus allowing you to set the `host` and `protocol` on the link."
			);
		}

		// Look up actual route paths instead of providing default Wheels path generation.
		// Loop over all routes to find matching one, break the loop on first match.
		// If the route is already in the cache we get it from there instead.
		if (!Len(arguments.route) && Len(arguments.action)) {
			if (!Len(arguments.controller)) {
				arguments.controller = local.params.controller;
			}
			local.key = arguments.controller & "##" & arguments.action;
			local.cache = request.wheels.urlForCache;
			if (!StructKeyExists(local.cache, local.key)) {
				local.iEnd = ArrayLen(application.wheels.routes);
				for (local.i = 1; local.i <= local.iEnd; local.i++) {
					local.route = application.wheels.routes[local.i];
					local.controllerMatch = StructKeyExists(local.route, "controller") && local.route.controller == arguments.controller;
					local.actionMatch = StructKeyExists(local.route, "action") && local.route.action == arguments.action;
					if (local.controllerMatch && local.actionMatch) {
						arguments.route = local.route.name;
						local.cache[local.key] = arguments.route;
						break;
					}
				}
			}
			if (StructKeyExists(local.cache, local.key)) {
				arguments.route = local.cache[local.key];
			}
		}

		// Start building the URL to return by setting the sub folder path and script name portion.
		// Script name index.cfm will be removed later if applicable (e.g. when URL rewriting is on).
		local.rv = application.wheels.webPath & ListLast(request.cgi.script_name, "/");

		// Look up route pattern to use and add it to the URL to return.
		// Either from a passed in route or the Wheels default one.
		// For the Wheels default we set the controller and action arguments to what's in the params struct.
		if (Len(arguments.route)) {
			local.route = $findRoute(argumentCollection = arguments);
			local.foundVariables = local.route.foundvariables;

			if (arguments.$URLRewriting neq "Off") {
				local.rv &= local.route.pattern;
			} else {
				// Always include core variables when not rewriting
				local.foundVariables &= "," & local.coreVariables;
				local.rv &= "?controller=[controller]&action=[action]&key=[key]&format=[format]";
			}
		} else {
			local.route = {};
			local.foundVariables = local.coreVariables;
			local.rv &= "?controller=[controller]&action=[action]&key=[key]&format=[format]";
		}

		// Shared fallback logic for controller/action
		if (StructKeyExists(local, "params")) {
			// Handle action
			if (!Len(arguments.action)) {
				if (StructKeyExists(local.route, "action")) {
					arguments.action = local.route.action;
				} else if (Len(arguments.controller)) {
					arguments.action = "index";
				} else if (StructKeyExists(local.params, "action")) {
					arguments.action = local.params.action;
				}
			}

			// Handle controller
			if (!Len(arguments.controller)) {
				if (StructKeyExists(local.route, "controller")) {
					arguments.controller = local.route.controller;
				} else if (StructKeyExists(local.params, "controller")) {
					arguments.controller = local.params.controller;
				}
			}
		}

		// Replace each params variable with the correct value.
		for (local.i = 1; local.i <= ListLen(local.foundVariables); local.i++) {
			local.property = ListGetAt(local.foundVariables, local.i);
			local.reg = "\[\*?#local.property#\]";

			// Read necessary variables from different sources.
			if (StructKeyExists(arguments, local.property) && Len(arguments[local.property])) {
				local.value = arguments[local.property];
			} else if (StructKeyExists(local.route, local.property)) {
				local.value = local.route[local.property];
			} else if (Len(arguments.route) && arguments.$URLRewriting != "Off") {
				Throw(
					type = "Wheels.IncorrectRoutingArguments",
					message = "Incorrect Arguments",
					extendedInfo = "The route chosen by Wheels `#local.route.name#` requires the argument `#local.property#`. Pass the argument `#local.property#` or change your routes to reflect the proper variables needed."
				);
			} else {
				continue;
			}

			// If value is a model object, get its key value.
			if (IsObject(local.value)) {
				local.value = local.value.key();
			}

			// Any value we find from above, URL encode it here.
			if (arguments.encode && $get("encodeURLs")) {
				local.value = EncodeForURL($canonicalize(local.value));
				if (arguments.$encodeForHtmlAttribute) {
					local.value = EncodeForHTMLAttribute(local.value);
				}
			}

			// If property is not in pattern, store it in the params argument.
			if (!ReFind(local.reg, local.rv)) {
				if (!ListFindNoCase(local.coreVariables, local.property)) {
					arguments.params = ListAppend(arguments.params, "#local.property#=#local.value#", "&");
				}
				continue;
			}

			// Transform value before setting it in pattern.
			if (local.property == "controller" || local.property == "action") {
				local.value = hyphenize(local.value);
			} else if (application.wheels.obfuscateUrls) {
				local.value = obfuscateParam(local.value);
			}
			local.rv = ReReplace(local.rv, local.reg, local.value);
		}

		// Clean up unused keys in pattern.
		local.rv = ReReplace(local.rv, "((&|\?)\w+=|\/|\.)\[\*?\w+\]", "", "ALL");

		// When URL rewriting is on (or partially) we replace the "?controller="" stuff in the URL with just "/".
		if (arguments.$URLRewriting != "Off") {
			local.rv = Replace(local.rv, "?controller=", "/");
			local.rv = Replace(local.rv, "&action=", "/");
			local.rv = Replace(local.rv, "&key=", "/");
		}

		// When URL rewriting is on we remove the rewrite file name (e.g. index.cfm) from the URL so it doesn't show.
		// Also get rid of the double "/" that this removal typically causes.
		if (arguments.$URLRewriting == "On") {
			local.rv = Replace(local.rv, application.wheels.rewriteFile, "");
			local.rv = Replace(local.rv, "//", "/");
		}

		// Add params to the URL when supplied.
		if (Len(arguments.params)) {
			local.rv &= $constructParams(
				params = arguments.params,
				encode = arguments.encode,
				$encodeForHtmlAttribute = arguments.$encodeForHtmlAttribute,
				$URLRewriting = arguments.$URLRewriting
			);
		}

		// Add an anchor to the the URL when supplied.
		if (Len(arguments.anchor)) {
			local.rv &= "##" & arguments.anchor;
		}

		// Prepend the full URL if directed.
		if (!arguments.onlyPath) {
			local.rv = $prependUrl(path = local.rv, argumentCollection = arguments);
		}

		return local.rv;
	}

	/**
	 * Internal function.
	 * Called from get().
	 */
	public any function $get(required string name, string functionName = "") {
		local.appKey = $appKey();
		if (Len(arguments.functionName)) {
			local.rv = application[local.appKey].functions[arguments.functionName][arguments.name];
		} else {
			local.rv = application[local.appKey][arguments.name];
		}
		return local.rv;
	}

	/**
	 * Internal function.
	 * Called from set().
	 */
	public void function $set() {
		local.appKey = $appKey();
		if (ArrayLen(arguments) > 1) {
			for (local.key in arguments) {
				if (local.key != "functionName") {
					local.iEnd = ListLen(arguments.functionName);
					for (local.i = 1; local.i <= local.iEnd; local.i++) {
						local.functionName = Trim(ListGetAt(arguments.functionName, local.i));
						application[local.appKey].functions[local.functionName][local.key] = arguments[local.key];
					}
				}
			}
		} else {
			application[local.appKey][StructKeyList(arguments)] = arguments[1];
		}
	}

	/**
	 * Capitalizes all words in the text to create a nicer looking title.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @string String to capitalize.
	 */
	public string function capitalize(required string text) {
		local.rv = arguments.text;
		if (Len(local.rv)) {
			local.rv = UCase(Left(local.rv, 1)) & Mid(local.rv, 2, Len(local.rv) - 1);
		}
		return local.rv;
	}

	/**
	 * Returns readable text by capitalizing and converting camel casing to multiple words.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @text Text to humanize.
	 * @except A list of strings (space separated) to replace within the output.
	 *
	 */
	public string function humanize(required string text, string except = "") {
		// add a space before every capitalized word
		local.rv = ReReplace(arguments.text, "([[:upper:]])", " \1", "all");

		// remove space after punctuation chars
		local.rv = ReReplace(local.rv, "([[:punct:]])([[:space:]])", "\1", "all");

		// fix abbreviations so they form a word again (example: aURLVariable)
		local.rv = ReReplace(local.rv, "([[:upper:]]) ([[:upper:]])(?:\s|\b)", "\1\2", "all");
		local.rv = ReReplace(local.rv, "([[:upper:]])([[:upper:]])([[:lower:]])", "\1\2 \3", "all");

		if (Len(arguments.except)) {
			local.iEnd = ListLen(arguments.except, " ");
			for (local.i = 1; local.i <= local.iEnd; local.i++) {
				local.item = ListGetAt(arguments.except, local.i);
				local.rv = ReReplaceNoCase(local.rv, "#local.item#(?:\b)", "#local.item#", "all");
			}
		}

		// support multiple word input by stripping out all double spaces created
		local.rv = Replace(local.rv, "  ", " ", "all");

		// capitalize the first letter and trim final result (which removes the leading space that happens if the string starts with an upper case character)
		local.rv = Trim(capitalize(local.rv));
		return local.rv;
	}

	/**
	 * Returns the plural form of the passed in word. Can also pluralize a word based on a value passed to the `count` argument. Wheels stores a list of words that are the same in both singular and plural form (e.g. "equipment", "information") and words that don't follow the regular pluralization rules (e.g. "child" / "children", "foot" / "feet"). Use `get("uncountables")` / `set("uncountables", newList)` and `get("irregulars")` / `set("irregulars", newList)` to modify them to suit your needs.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @word The word to pluralize.
	 * @count Pluralization will occur when this value is not 1.
	 * @returnCount Will return count prepended to the pluralization when true and count is not -1.
	 */
	public string function pluralize(required string word, numeric count = "-1", boolean returnCount = "true") {
		return $singularizeOrPluralize(
			count = arguments.count,
			returnCount = arguments.returnCount,
			text = arguments.word,
			which = "pluralize"
		);
	}

	/**
	 * Returns the singular form of the passed in word.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @string String to singularize.
	 */
	public string function singularize(required string word) {
		return $singularizeOrPluralize(text = arguments.word, which = "singularize");
	}

	/**
	 * Converts camelCase strings to lowercase strings with hyphens as word delimiters instead. Example: myVariable becomes my-variable.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @string The string to hyphenize.
	 */
	public string function hyphenize(required string string) {
		local.rv = ReReplace(arguments.string, "([A-Z][a-z])", "-\l\1", "all");
		local.rv = ReReplace(local.rv, "([a-z])([A-Z])", "\1-\l\2", "all");
		local.rv = ReReplace(local.rv, "^-", "", "one");
		local.rv = LCase(local.rv);
		return local.rv;
	}

	/**
	 * Capitalizes all words in the text to create a nicer looking title.
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @word The text to turn into a title.
	 */
	public string function titleize(required string word) {
		local.rv = "";
		local.iEnd = ListLen(arguments.word, " ");
		for (local.i = 1; local.i <= local.iEnd; local.i++) {
			local.rv = ListAppend(local.rv, capitalize(ListGetAt(arguments.word, local.i, " ")), " ");
		}
		return local.rv;
	}

	public array function $splitOutsideFunctions(required string list, required string splitBy) {
		local.rv = [];
		local.temp = "";
		local.insideFunction = false;
		local.bracketCount = 0;

		for (local.i = 1; i <= len(arguments.list); i++) {
			local.char = mid(arguments.list, i, 1);

			// Check if we are entering or exiting a function's parentheses
			if (local.char == "(") {
				local.bracketCount++;
			} else if (local.char == ")") {
				local.bracketCount--;
			}

			// Determine if we are inside a function (any content enclosed by parentheses)
			if (local.bracketCount > 0) {
				local.insideFunction = true;
			} else if (local.bracketCount == 0) {
				local.insideFunction = false;
			}

			// Split based on commas outside functions
			if (local.char == arguments.splitBy && !local.insideFunction) {
				arrayAppend(local.rv, trim(local.temp));
				local.temp = "";
			} else {
				local.temp &= local.char;
			}
		}

		// Append the final segment
		if (len(trim(local.temp))) {
			arrayAppend(local.rv, trim(local.temp));
		}

		return local.rv;
	}

	/**
	 * Normalizes a nested key path by converting bracket notation (e.g., `form[user][email]`) to dot notation (e.g., `form.user.email`).
	 *
	 * [section: Global Helpers]
	 * [category: String Functions]
	 *
	 * @path The key path to normalize.
	 */
	public string function $normalizePath(required string path) {
		local.norm = arguments.path;
		local.norm = reReplace(local.norm, "\[(.*?)\]", ".\1", "all");
		local.norm = reReplace(local.norm, "^\.", "", "one");
		return local.norm;
	}

	/**
	 * Generates a 36-character UUID compatible with SQL Server's uniqueidentifier.
	 *
	 * [section: Global Helpers]
	 * [category: UUID Functions]
	 *
	 * @return A valid 36-character UUID string (e.g., 123e4567-e89b-12d3-a456-426614174000)
	 */
	public string function generateUUID() {
		// Use Java UUID generator for a 36-character format
		return createObject("java", "java.util.UUID").randomUUID().toString();
	}

	include "/app/global/functions.cfm";
}
