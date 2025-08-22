<cfscript>
    //=====================================================================
    //= 	Global Functions
    //=====================================================================
    if (StructKeyExists(server, "lucee")) {
        include "install.cfm";
        include "auth.cfm";
        include "logging.cfm";
        include "utils.cfm";
    } else {
        // TODO: Check this doesn't break when in a subdir?
        include "/global/install.cfm";
        include "/global/auth.cfm";
        include "/global/logging.cfm";
        include "/global/utils.cfm";
    }
</cfscript>
