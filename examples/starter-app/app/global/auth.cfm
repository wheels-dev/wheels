<cfscript>
//=====================================================================
//= 	Global Authentication Functions
//=====================================================================
    /**
    * Gets the users session; if we're running tests, we switch out the session to the request scope
    * As running the test from the CLI means we can't easily test against a session.
    *
    * [section: Application]
    * [category: Authentication]
    */
    function getSession(){
        if(structKeyExists(request, "isTestingMode")){
            return request.mockSession;
        } else {
            return session;
        }
    }
    /**
    * Checks for existence of a valid session, and whether the auth object exists
    *
    * [section: Application]
    * [category: Authentication]
    */
    function isAuthenticated(){
        return structKeyExists(getSession(), "user");
    }
    /**
    * Logs a user out deleting and invalidating session
    *
    * [section: Application]
    * [category: Authentication]
    */
    function forcelogout(){
        // Is this really necessary? Or do we just need sessionInvalidate?
        if(structKeyExists(getSession(), "user")){
            structDelete(getSession(), "user");
            if(!structKeyExists(request, "isTestingMode")){
                sessionInvalidate();
            }
        }
    }
    /**
    * Set a session flag for an authenticated user which prevents them from further progress
    * until they change their password
    *
    * [section: Application]
    * [category: Authentication]
    */
    function createPasswordResetBlock(){
         getSession()["blockedByPassword"]=now();
    }

    /**
    * Clear the session flag for an authenticated user which prevents them from further progress
    * until they change their password
    *
    * [section: Application]
    * [category: Authentication]
    */
    function clearPasswordResetBlock(){
         structDelete(getSession(), "blockedByPassword");
    }
    /**
    * Test for the session flag for an authenticated user which prevents them from further progress
    * until they change their password
    *
    * [section: Application]
    * [category: Authentication]
    */
    function hasPasswordResetBlock(){
        return structKeyExists(getSession(), "blockedByPassword");
    }

//=====================================================================
//=     Permission System
//=====================================================================

    /**
    * This is the main method to essentially login a user:
    * it gets their permissions dependent on their userid and role, merges them into a single struct
    * and then stores that in the session scope. Pass in a user object.
    *
    * [section: Application]
    * [category: Permissions]
    *
    * @user The User Object
    */
    function assignPermissions(required struct user){
        // If coming from an external auth source, it might be that the the roleid is set in active directory (for instance)
        local.rolePermissions=getRolePermissions(arguments.user.roleid);
        // Get User Permissions from local user account which override Role based permissions
        local.userPermissions=getUserPermissions(arguments.user.id);
        // Merge Permissions in Scope
        local.permissions=mergePermissions(local.rolePermissions, local.userPermissions);
        // Store convienient data in Session Scope
        getSession()["user"]={
            "permissions"= {},
            "properties" = arguments.user.properties()
        };
        for(permission in local.permissions){
            getSession()["user"]["permissions"][permission]=true;
        }
    }

    /**
    * Manually call permission("admin.users.index")
    * checks session.user.permissions
    * should then return a boolean, false by default;
    * Automatically should default to current controller + action
    * Permission is stored in db as a string, so calendar.show
    * If cascade = false:
    *  a permission of admin.bookings.new would require admin AND admin.bookings AND admin.bookings.new
    * if cascade = true:
    *  a permission of admin.bookings.new would require admin OR admin.bookings OR admin.bookings.new
    *  as the prescence of admin or admin.bookings higher up the chain would cascade DOWN to admin.bookings.new
    *
    * [section: Application]
    * [category: Permissions]
    *
    * @permission a string such as "admin.users": defaults to the controller + action in the params scope
    * @userpermissions Override user permissions with another scope
    * @debug force return of a struct of all values for debugging
    */
    public any function hasPermission(
        string permission=getDefaultPermissionString(),
        struct userpermissions=getCurrentUserPermissions(),
        boolean debug=false
    ){
        local.rv                = false;
        local.passes            = [];
        local.fails             = [];
        local.permission        = arguments.permission;
        local.permissions       = getPermissionArr(arguments.permission);
        local.userPermissions   = arguments.userpermissions;
        local.cascade           = getSetting("permissions_cascade");

        if(local.cascade){
            // If user has the permission required, or any permission ABOVE, approve
            for(p in local.permissions){
                if(structKeyExists(local.userPermissions, p) && !arguments.debug && local.userPermissions[p]){
                    local.rv=true;
                    arrayAppend(local.passes, { "#p#": true });
                } else if(structKeyExists(local.userPermissions, p) && arguments.debug) {
                    local.rv=true;
                    arrayAppend(local.passes, { "#p#": true });
                }
            }

        } else {
            for(p in local.permissions){
                // If auth'd check session
                if(structKeyExists(local.userPermissions, p) && local.userPermissions[p]){
                    arrayAppend(local.passes, { "#p#": true });
                } else {
                    arrayAppend(local.fails, { "#p#": false });
                }
            }

            // If user has ALL the permissions required, approve
            if(arraylen(local.passes) == arraylen(local.permissions) && !arraylen(local.fails)){
                local.rv=true;
            }
        }
        if(arguments.debug){
            return local;
        } else {
            return local.rv;
        }
    }
    /**
    * Returns the User Permissions Scope
    *
    * [section: Application]
    * [category: Permissions]
    */
    public struct function getCurrentUserPermissions(){
        if(isAuthenticated() && structKeyExists(getSession().user, "permissions")){
            return getSession().user.permissions;
        } else {
            return {};
        }
    }
    /**
    * Attempts to construct a default permission string by nested controller + action
    *
    * [section: Application]
    * [category: Permissions]
    */
    public string function getDefaultPermissionString(){
        local.string="";
        if(isDefined("params")){
            if(structKeyExists(params, "Controller")) local.string &= params.controller;
            if(structKeyExists(params, "Action") && len(params.action)) local.string &= '.' & params.action;
        }
        return lcase(local.string);
    }

    /**
    * Convert sa dot notation string to an array
    *
    * [section: Application]
    * [category: Permissions]
    *
    * @permission a string such as "admin.users"
    */
    public array function getPermissionArr(required string permission){
        local.rv=[];
        local.t="";
        local.arr=listToArray(lcase(arguments.permission), '.');
        for(local.p in local.arr){
            local.t&='.' & local.p;
            arrayAppend(local.rv, right(local.t, (len(local.t)-1) ) );
        }
        return local.rv;
    }
//=====================================================================
//=     Shared Authentication Model Functions
//=====================================================================
    /**
    * Given a roleid, get relevant role based permissions
    * If roleid == 0, which is the default, then no role has been assigned - used in assignPermissions()
    *
    * [section: Application]
    * [category: Permissions]
    */
    struct function getRolePermissions(required numeric roleid){
        local.permissions={};
        if(roleid != 0){
            local.permissionQ=model("rolepermission").findAll(where="roleid=#roleid#", include="permission");
            for(permission in local.permissionQ){
                permission["setby"]="Role";
                local.permissions[permission.name]=permission;
            }
        }
        return local.permissions;
    }
    /**
    * Given a userid, get user permissions - used in assignPermissions()
    *
    * [section: Application]
    * [category: Permissions]
    */
    struct function getUserPermissions(required numeric userid){
        local.permissions={};
        if(userid != 0){
            local.permissionQ=model("userpermission").findAll(where="userid=#userid#", include="permission");
            for(permission in local.permissionQ){
                permission["setby"]="User";
                local.permissions[permission.name]=permission;
            }
        }
        return local.permissions;
    }
    /**
    * Start with Role Permissions and Override with User Permissions - used in assignPermissions()
    *
    * [section: Application]
    * [category: Permissions]
    */
    struct function mergePermissions(required struct rolePermissions, required struct userPermissions){
        local.permissions={};
        if(structIsEmpty(userPermissions)){
            local.permissions=rolePermissions;
        } else {
            for(permission in userPermissions){
                rolePermissions[permission]=userPermissions[permission];
            }
            local.permissions=rolePermissions;
        }
        return local.permissions;
    }

//=====================================================================
//=     Remember me cookie functions
//=====================================================================

    /**
    * Sets a cookie which remembers the login
    *
    * [section: Application]
    * [category: Authentication]
    *
    * @email The email to remember
    */
    function setCookieRememberEmail(required string email) {
        // Try and work out if we're using HTTPS and if so, set secure flag;
        // NB you'll need to set this.sessioncookie.secure for cfml sessions in config/app.cfm if using SSL
        local.useSecure = (cgi.https eq "on")? true: false;
        local.encString = encryptString(arguments.email);
        cfcookie(expires=360, name="rememberme", value=local.encString, httponly=true, secure=local.useSecure);
        addlogline(message="#arguments.email# used cookie remember email", severity="info", type="auth");
    }

    /**
    * Remove the username/email cookie
    *
    * [section: Application]
    * [category: Authentication]
    *
    */
    function deleteCookieRememberEmail() {
        cfcookie(expires=now(), name="rememberme");
        addlogline(message="Cookie remember email removed", severity="info", type="auth");
    }

//=====================================================================
//=     General purpose encrypt/decrypt functions
//=====================================================================
    /**
    * Encrypt a value using the main application key
    *
    * [section: Application]
    * [category: Authentication]
    *
    * @value the string to encrypt
    *
    */
    function encryptString(required string value) {
        return encrypt(arguments.value, application.encryptionKey, "AES/CBC/PKCS5Padding", "HEX" );
    }

    /**
    * Decrypt a value using the main application key
    *
    * [section: Application]
    * [category: Authentication]
    *
    * @value the string to decrypt
    *
    */
    function decryptString(required string value) {
        return decrypt(arguments.value, application.encryptionKey, "AES/CBC/PKCS5Padding", "HEX" );
    }
</cfscript>

