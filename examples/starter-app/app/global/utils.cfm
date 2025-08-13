<cfscript>
//=====================================================================
//= 	Global Utils
//=====================================================================

/**
* Converts a dot notation string to a struct
*
* [section: Application]
* [category: Utils]
*
* @key a string such as "admin.users"
* @value i.e, false
* @delimiter optional delimter
*/
public struct function convertStringToStruct(required string key, required any value, string delimiter = ".") {
    local.obj   = {};
    local.first = ListFirst(arguments.key, arguments.delimiter);
    local.rest  = ListRest(arguments.key, arguments.delimiter);
    if(Len(rest)) {
        local.obj[local.first] = convertStringToStruct(local.rest, arguments.value, arguments.delimiter);
    } else {
        local.obj[local.first] = arguments.value;
    }
    return local.obj;
}

/**
* Gets IP address checking for forwarded for headers
*
* [section: Application]
* [category: Utils]
*/
public string function getIPAddress() {
    local.rv = "";
    try {
        try {
            local.headers = getHttpRequestData().headers;
            if (structKeyExists(local.headers, "X-Forwarded-For") && len(local.headers["X-Forwarded-For"]) > 0) {
                local.rv = trim(listFirst(local.headers["X-Forwarded-For"]));
            }
        } catch (any e) {}
        if (len(local.rv) == 0) {
            if (structKeyExists(cgi, "remote_addr") && len(cgi.remote_addr) > 0) {
                local.rv = cgi.remote_addr;
            } else if (structKeyExists(cgi, "remote_host") && len(cgi.remote_host) > 0) {
                local.rv = cgi.remote_host;
            }
        }
    } catch (any e) {}
    return local.rv;
}

/**
* I get an application setting from the main application settings
*
* [section: Application]
* [category: Utils]
*
* @key The setting name to get
*/
function getSetting(required string key) {
    if(structKeyExists(request, "isTestingMode") && structKeyExists(request, "mockApplication")){
        return request.mockApplication[arguments.key];
    } else {
        return application.settings[arguments.key];
    }
}

/**
 * I surround each array element in brackets and return delimited by an operator
 * Used to construct more complex where clauses for findall etc
 *
 * [section: Application]
 * [category: Utils]
 *
 * @array The array of conditions
 * @operator Either AND or OR
 */
public string function whereify(required array array, string operator="AND") {
    var loc = {};
    loc.array = [];
    for (loc.i=1; loc.i <= ArrayLen(arguments.array); loc.i++) {
        loc.array[loc.i] = "(#arguments.array[loc.i]#)";
    }
    return ArrayToList(loc.array, " #arguments.operator# ");
}

/**
 * Get All Roles for use in application settings
 *
 * [section: Application]
 * [category: Utils]
 */
public function getRoleDropdownList(){
    return model("role").findAll();
}
/**
 * Get All Timezones for use in application settings
 *
 * [section: Application]
 * [category: Utils]
 */
function getTZListDropDown(){
    var list = createObject("java", "java.util.TimeZone").getAvailableIDs();
    var data = {};
    for (tz in list){
        var ms = createObject("java", "java.util.TimeZone").getTimezone( tz ).getOffset( getTickCount() );
        data[ tz ] = tz & " [" & readableOffset( ms ) & "]";
    }
    return data;
}
/**
 * Create a readable offset used in getTZListDropDown()
 *
 * [section: Application]
 * [category: Utils]
 *
 * @offset
 */
 function readableOffset( offset ){
    var h = offset / 1000 / 60 / 60; //raw hours (decimal) offset
    var hh = fix( h ); //int hours
    var mm = ( hh == h ? ":00" : ":" & abs(round((h-hh)*60)) ); //hours modulo used to determine minutes
    var rep = ( h >= 0 ? "+" : "" ) & hh & mm;
    return rep;
}
/**
 * Return a list of available locales from Java
 *
 * [section: Application]
 * [category: Utils]
 *
 */
public function getLocaleListDropDown(){
    local.rv=server.coldfusion.supportedlocales;
    local.rv=listSort(local.rv, "textnocase");
    return local.rv;
}
</cfscript>
